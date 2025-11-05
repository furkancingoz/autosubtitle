//
//  VideoJob.swift
//  AutoSubtitle
//
//  Model representing a video subtitle generation job
//

import Foundation
import FirebaseFirestore

struct VideoJob: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var status: JobStatus
    var localVideoURL: String? // Local file path
    var videoFileName: String
    var videoDuration: TimeInterval
    var videoSizeBytes: Int64
    var creditsDeducted: Int
    var creditsRefunded: Int
    var falRequestId: String?
    var resultVideoURL: String? // Remote URL from fal.ai
    var transcription: String?
    var subtitleCount: Int?
    var language: String
    var createdAt: Date
    var startedProcessingAt: Date?
    var completedAt: Date?
    var errorMessage: String?
    var retryCount: Int
    var maxRetries: Int

    // Customization options
    var fontName: String
    var fontSize: Int
    var fontColor: String
    var highlightColor: String
    var position: SubtitlePosition

    enum CodingKeys: String, CodingKey {
        case id, userId, status, localVideoURL, videoFileName
        case videoDuration, videoSizeBytes, creditsDeducted, creditsRefunded
        case falRequestId, resultVideoURL, transcription, subtitleCount
        case language, createdAt, startedProcessingAt, completedAt
        case errorMessage, retryCount, maxRetries
        case fontName, fontSize, fontColor, highlightColor, position
    }

    init(
        id: String? = nil,
        userId: String,
        status: JobStatus = .idle,
        localVideoURL: String? = nil,
        videoFileName: String,
        videoDuration: TimeInterval,
        videoSizeBytes: Int64,
        creditsDeducted: Int = 0,
        creditsRefunded: Int = 0,
        falRequestId: String? = nil,
        resultVideoURL: String? = nil,
        transcription: String? = nil,
        subtitleCount: Int? = nil,
        language: String = "en",
        createdAt: Date = Date(),
        startedProcessingAt: Date? = nil,
        completedAt: Date? = nil,
        errorMessage: String? = nil,
        retryCount: Int = 0,
        maxRetries: Int = 3,
        fontName: String = "Montserrat",
        fontSize: Int = 100,
        fontColor: String = "#FFFFFF",
        highlightColor: String = "#A855F7",
        position: SubtitlePosition = .bottom
    ) {
        self.id = id
        self.userId = userId
        self.status = status
        self.localVideoURL = localVideoURL
        self.videoFileName = videoFileName
        self.videoDuration = videoDuration
        self.videoSizeBytes = videoSizeBytes
        self.creditsDeducted = creditsDeducted
        self.creditsRefunded = creditsRefunded
        self.falRequestId = falRequestId
        self.resultVideoURL = resultVideoURL
        self.transcription = transcription
        self.subtitleCount = subtitleCount
        self.language = language
        self.createdAt = createdAt
        self.startedProcessingAt = startedProcessingAt
        self.completedAt = completedAt
        self.errorMessage = errorMessage
        self.retryCount = retryCount
        self.maxRetries = maxRetries
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.highlightColor = highlightColor
        self.position = position
    }

    var canRetry: Bool {
        retryCount < maxRetries && (status == .failed || status == .error)
    }

    var processingTime: TimeInterval? {
        guard let started = startedProcessingAt,
              let completed = completedAt else { return nil }
        return completed.timeIntervalSince(started)
    }

    var statusIcon: String {
        switch status {
        case .idle: return "circle"
        case .validating: return "checkmark.circle"
        case .uploading: return "arrow.up.circle"
        case .queued: return "clock"
        case .processing: return "gearshape.2"
        case .downloading: return "arrow.down.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed, .error: return "xmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .refunded: return "arrow.uturn.backward"
        }
    }

    var statusColor: String {
        switch status {
        case .idle: return "gray"
        case .validating, .uploading, .queued, .processing, .downloading: return "blue"
        case .completed: return "green"
        case .failed, .error: return "red"
        case .cancelled: return "orange"
        case .refunded: return "yellow"
        }
    }
}

enum JobStatus: String, Codable {
    case idle = "idle"
    case validating = "validating"
    case uploading = "uploading"
    case queued = "queued"
    case processing = "processing"
    case downloading = "downloading"
    case completed = "completed"
    case failed = "failed"
    case error = "error"
    case cancelled = "cancelled"
    case refunded = "refunded"

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .validating: return "Validating..."
        case .uploading: return "Uploading..."
        case .queued: return "In Queue"
        case .processing: return "Processing..."
        case .downloading: return "Downloading..."
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .error: return "Error"
        case .cancelled: return "Cancelled"
        case .refunded: return "Refunded"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .error, .cancelled, .refunded:
            return true
        default:
            return false
        }
    }

    var isProcessing: Bool {
        switch self {
        case .validating, .uploading, .queued, .processing, .downloading:
            return true
        default:
            return false
        }
    }
}

enum SubtitlePosition: String, Codable {
    case top = "top"
    case center = "center"
    case bottom = "bottom"

    var displayName: String {
        rawValue.capitalized
    }
}
