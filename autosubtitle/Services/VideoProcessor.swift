//
//  VideoProcessor.swift
//  AutoSubtitle
//
//  Orchestrates the video subtitle generation process
//

import Foundation
import AVFoundation
import Combine
import FirebaseFirestore

class VideoProcessor: ObservableObject {
    static let shared = VideoProcessor()

    @Published var currentJob: VideoJob?
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""

    private let falService = FalAIService.shared
    private let creditManager = CreditManager.shared
    private let userManager = UserManager.shared
    private var cancellables = Set<AnyCancellable>()

    private let maxFileSize: Int64 = 100 * 1024 * 1024 // 100 MB
    private let maxRetries = 3
    private let statusPollInterval: TimeInterval = 3.0
    private let maxProcessingTime: TimeInterval = 600 // 10 minutes

    private var statusCheckTask: Task<Void, Never>?

    private init() {}

    // MARK: - Process Video

    func processVideo(
        from videoURL: URL,
        language: String = "en",
        fontName: String = "Montserrat",
        fontSize: Int = 100,
        fontColor: String = "#FFFFFF",
        highlightColor: String = "#A855F7",
        position: SubtitlePosition = .bottom
    ) async throws -> VideoJob {

        guard let userId = FirebaseAuthManager.shared.userId else {
            throw VideoProcessorError.notAuthenticated
        }

        // Step 1: Validate Video
        updateStatus(.validating, "Validating video...")
        let videoInfo = try await validateVideo(videoURL)

        // Step 2: Check Credits
        let requiredCredits = creditManager.calculateRequiredCredits(for: videoInfo.duration)

        guard creditManager.hasEnoughCredits(for: videoInfo.duration) else {
            throw VideoProcessorError.insufficientCredits(required: requiredCredits, available: creditManager.creditBalance)
        }

        // Step 3: Create Job
        var job = VideoJob(
            userId: userId,
            status: .idle,
            localVideoURL: videoURL.path,
            videoFileName: videoURL.lastPathComponent,
            videoDuration: videoInfo.duration,
            videoSizeBytes: videoInfo.fileSize,
            language: language,
            fontName: fontName,
            fontSize: fontSize,
            fontColor: fontColor,
            highlightColor: highlightColor,
            position: position
        )

        DispatchQueue.main.async {
            self.currentJob = job
        }

        // Step 4: Deduct Credits (Pre-deduction)
        updateStatus(.uploading, "Deducting credits...")
        do {
            try await creditManager.deductCredits(
                requiredCredits,
                type: .deduction,
                reference: job.id,
                description: "Video processing: \(job.videoFileName)"
            )
            job.creditsDeducted = requiredCredits
            await userManager.incrementCreditsUsed(requiredCredits)
            print("💳 Credits deducted: \(requiredCredits)")
        } catch {
            updateStatus(.failed, "Failed to deduct credits")
            throw error
        }

        do {
            // Step 5: Upload Video
            updateStatus(.uploading, "Uploading video...")
            let remoteVideoURL = try await falService.uploadVideo(from: videoURL)

            // Step 6: Submit Request
            updateStatus(.queued, "Submitting request...")
            let request = FalAISubtitleRequest(
                videoUrl: remoteVideoURL,
                language: language,
                fontName: fontName,
                fontSize: fontSize,
                fontWeight: "bold",
                fontColor: fontColor,
                highlightColor: highlightColor,
                position: position.rawValue
            )

            let requestId = try await falService.submitRequest(request)
            job.falRequestId = requestId
            job.startedProcessingAt = Date()

            // Step 7: Poll Status
            updateStatus(.processing, "Processing video...")
            let result = try await pollStatus(requestId: requestId, job: &job)

            // Step 8: Download Result
            updateStatus(.downloading, "Downloading result...")
            let localResultURL = try await downloadResult(result: result, job: &job)

            // Step 9: Complete Job
            job.status = .completed
            job.completedAt = Date()
            job.resultVideoURL = localResultURL.path
            job.transcription = result.transcription
            job.subtitleCount = result.subtitleCount

            updateStatus(.completed, "Completed!")
            await userManager.incrementVideosProcessed()

            // Save job to Firebase
            try await saveJob(job)

            DispatchQueue.main.async {
                self.currentJob = job
            }

            print("✅ Video processing completed successfully")
            return job

        } catch {
            // Error handling: Refund credits
            print("❌ Processing failed: \(error.localizedDescription)")

            job.status = .failed
            job.errorMessage = error.localizedDescription
            job.completedAt = Date()

            // Refund credits
            if job.creditsDeducted > 0 && job.creditsRefunded == 0 {
                do {
                    try await creditManager.refundCredits(
                        job.creditsDeducted,
                        reference: job.id,
                        description: "Refund for failed video: \(job.videoFileName)"
                    )
                    job.creditsRefunded = job.creditsDeducted
                    print("💰 Credits refunded: \(job.creditsDeducted)")
                } catch {
                    print("❌ Failed to refund credits: \(error.localizedDescription)")
                }
            }

            // Check if retry is possible
            if job.canRetry && shouldRetry(error: error) {
                updateStatus(.failed, "Retrying...")
                job.retryCount += 1

                // Save failed job
                try? await saveJob(job)

                // Retry
                return try await retryJob(job)
            }

            updateStatus(.failed, error.localizedDescription)

            // Save failed job
            try? await saveJob(job)

            DispatchQueue.main.async {
                self.currentJob = job
            }

            throw error
        }
    }

    // MARK: - Retry

    func retryJob(_ job: VideoJob) async throws -> VideoJob {
        guard let videoURL = job.localVideoURL.flatMap({ URL(fileURLWithPath: $0) }) else {
            throw VideoProcessorError.videoFileNotFound
        }

        print("🔄 Retrying job (attempt \(job.retryCount + 1)/\(job.maxRetries))")

        return try await processVideo(
            from: videoURL,
            language: job.language,
            fontName: job.fontName,
            fontSize: job.fontSize,
            fontColor: job.fontColor,
            highlightColor: job.highlightColor,
            position: job.position
        )
    }

    // MARK: - Cancel

    func cancelJob() async {
        guard let job = currentJob,
              let requestId = job.falRequestId,
              job.status.isProcessing else {
            return
        }

        statusCheckTask?.cancel()

        do {
            try await falService.cancelRequest(requestId: requestId)

            var updatedJob = job
            updatedJob.status = .cancelled
            updatedJob.completedAt = Date()

            // Refund credits
            if updatedJob.creditsDeducted > 0 && updatedJob.creditsRefunded == 0 {
                try await creditManager.refundCredits(
                    updatedJob.creditsDeducted,
                    reference: updatedJob.id,
                    description: "Refund for cancelled video: \(updatedJob.videoFileName)"
                )
                updatedJob.creditsRefunded = updatedJob.creditsDeducted
            }

            try await saveJob(updatedJob)

            DispatchQueue.main.async {
                self.currentJob = updatedJob
            }

            print("🚫 Job cancelled")
        } catch {
            print("❌ Failed to cancel job: \(error.localizedDescription)")
        }
    }

    // MARK: - Validation

    private func validateVideo(_ url: URL) async throws -> (duration: TimeInterval, fileSize: Int64) {
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw VideoProcessorError.videoFileNotFound
        }

        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            throw VideoProcessorError.invalidVideo
        }

        // Check file size
        guard fileSize <= maxFileSize else {
            throw VideoProcessorError.fileTooLarge(size: fileSize, max: maxFileSize)
        }

        // Get video duration
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        guard durationSeconds > 0 && durationSeconds.isFinite else {
            throw VideoProcessorError.invalidVideo
        }

        // Check if video has audio
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw VideoProcessorError.noAudioTrack
        }

        print("✅ Video validated: \(durationSeconds)s, \(fileSize) bytes")
        return (durationSeconds, fileSize)
    }

    // MARK: - Status Polling

    private func pollStatus(requestId: String, job: inout VideoJob) async throws -> FalAIResultResponse {
        let startTime = Date()

        return try await withCheckedThrowingContinuation { continuation in
            statusCheckTask = Task {
                var pollInterval = statusPollInterval
                var hasResumed = false

                while !Task.isCancelled {
                    // Check timeout
                    if Date().timeIntervalSince(startTime) > maxProcessingTime {
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: VideoProcessorError.timeout)
                        }
                        return
                    }

                    do {
                        let statusResponse = try await falService.checkStatus(requestId: requestId)
                        let status = statusResponse.falStatus

                        print("📊 Status: \(status.rawValue)")

                        switch status {
                        case .completed:
                            // Fetch result
                            let result = try await falService.getResult(requestId: requestId)
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(returning: result)
                            }
                            return

                        case .failed:
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(throwing: VideoProcessorError.processingFailed("API processing failed"))
                            }
                            return

                        case .cancelled:
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(throwing: VideoProcessorError.cancelled)
                            }
                            return

                        case .inQueue:
                            updateStatus(.queued, "In queue...")

                        case .inProgress:
                            updateStatus(.processing, "Processing...")

                        case .unknown:
                            break
                        }

                        // Exponential backoff
                        try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                        pollInterval = min(pollInterval * 1.5, 10.0) // Max 10s

                    } catch {
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: error)
                        }
                        return
                    }
                }

                // Task was cancelled
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: VideoProcessorError.cancelled)
                }
            }
        }
    }

    // MARK: - Download

    private func downloadResult(result: FalAIResultResponse, job: inout VideoJob) async throws -> URL {
        guard let videoFile = result.video else {
            throw VideoProcessorError.noResultVideo
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "subtitle_\(UUID().uuidString).mp4"
        let localURL = documentsPath.appendingPathComponent(fileName)

        try await falService.downloadVideo(from: videoFile.url, to: localURL)

        return localURL
    }

    // MARK: - Save Job

    private func saveJob(_ job: VideoJob) async throws {
        guard let userId = FirebaseAuthManager.shared.userId else { return }

        let db = FirebaseFirestore.Firestore.firestore()
        let jobRef = db.collection("users").document(userId).collection("jobs")

        if let jobId = job.id {
            try jobRef.document(jobId).setData(from: job, merge: true)
        } else {
            try jobRef.addDocument(from: job)
        }
    }

    // MARK: - Helpers

    private func updateStatus(_ status: JobStatus, _ message: String) {
        DispatchQueue.main.async {
            self.currentJob?.status = status
            self.statusMessage = message
        }
    }

    private func shouldRetry(error: Error) -> Bool {
        // Retry on network errors and timeouts, but not on validation errors
        if let processorError = error as? VideoProcessorError {
            switch processorError {
            case .timeout, .networkError:
                return true
            default:
                return false
            }
        }

        if let falError = error as? FalAIError {
            switch falError {
            case .timeout, .statusCheckFailed, .uploadFailed:
                return true
            default:
                return false
            }
        }

        return false
    }
}

// MARK: - Error Types

enum VideoProcessorError: LocalizedError, Identifiable {
    case notAuthenticated
    case videoFileNotFound
    case invalidVideo
    case noAudioTrack
    case fileTooLarge(size: Int64, max: Int64)
    case insufficientCredits(required: Int, available: Int)
    case uploadFailed(String)
    case processingFailed(String)
    case timeout
    case cancelled
    case noResultVideo
    case networkError(String)

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to process videos"
        case .videoFileNotFound:
            return "Video file not found"
        case .invalidVideo:
            return "Invalid video file"
        case .noAudioTrack:
            return "Video has no audio track"
        case .fileTooLarge(let size, let max):
            let sizeMB = Double(size) / (1024 * 1024)
            let maxMB = Double(max) / (1024 * 1024)
            return String(format: "File too large (%.1f MB). Maximum size is %.0f MB", sizeMB, maxMB)
        case .insufficientCredits(let required, let available):
            return "Not enough credits. Required: \(required), Available: \(available)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .timeout:
            return "Processing timed out. Please try again with a shorter video."
        case .cancelled:
            return "Processing was cancelled"
        case .noResultVideo:
            return "No result video received from server"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
