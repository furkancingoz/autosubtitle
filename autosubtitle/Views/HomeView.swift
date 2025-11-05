//
//  HomeView.swift
//  AutoSubtitle
//
//  Main screen for video upload and processing
//

import SwiftUI
import PhotosUI
import AVKit

struct HomeView: View {
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var videoProcessor: VideoProcessor
    @EnvironmentObject var userManager: UserManager

    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    @State private var showVideoPicker = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Customization options
    @State private var language = "en"
    @State private var fontName = "Montserrat"
    @State private var fontSize = 100
    @State private var fontColor = "#FFFFFF"
    @State private var highlightColor = "#A855F7"
    @State private var position: SubtitlePosition = .bottom

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Credit Balance Card
                    creditBalanceCard

                    // Video Selection
                    if let videoURL = selectedVideoURL {
                        videoPreviewCard(videoURL: videoURL)
                    } else {
                        videoPickerCard
                    }

                    // Customization Options
                    if selectedVideoURL != nil {
                        customizationSection
                    }

                    // Process Button
                    if selectedVideoURL != nil {
                        processButton
                    }

                    // Processing Status
                    if let job = videoProcessor.currentJob, job.status.isProcessing {
                        processingStatusCard
                    }

                    // Result
                    if let job = videoProcessor.currentJob, job.status == .completed {
                        resultCard(job: job)
                    }
                }
                .padding()
            }
            .navigationTitle("AutoSubtitle")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Components

    private var creditBalanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Credit Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(creditManager.creditBalance)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.purple)
            }

            Spacer()

            Button("Add Credits") {
                showPaywall = true
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.purple)
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var videoPickerCard: some View {
        PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
            VStack(spacing: 16) {
                Image(systemName: "video.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)

                Text("Select a Video")
                    .font(.headline)

                Text("Choose a video from your library")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .onChange(of: selectedVideoItem) { newItem in
            Task {
                await loadVideo(from: newItem)
            }
        }
    }

    private func videoPreviewCard(videoURL: URL) -> some View {
        VStack(spacing: 12) {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(height: 200)
                .cornerRadius(12)

            HStack {
                Text(videoURL.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)

                Spacer()

                Button("Change") {
                    selectedVideoURL = nil
                    selectedVideoItem = nil
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customization")
                .font(.headline)

            VStack(spacing: 12) {
                // Language
                HStack {
                    Text("Language")
                    Spacer()
                    Picker("Language", selection: $language) {
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("German").tag("de")
                        Text("Portuguese").tag("pt")
                    }
                    .pickerStyle(.menu)
                }

                Divider()

                // Position
                HStack {
                    Text("Position")
                    Spacer()
                    Picker("Position", selection: $position) {
                        Text("Top").tag(SubtitlePosition.top)
                        Text("Center").tag(SubtitlePosition.center)
                        Text("Bottom").tag(SubtitlePosition.bottom)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                Divider()

                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(fontSize)")
                    Slider(value: Binding(
                        get: { Double(fontSize) },
                        set: { fontSize = Int($0) }
                    ), in: 20...150, step: 10)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private var processButton: some View {
        Button(action: processVideo) {
            if videoProcessor.currentJob?.status.isProcessing == true {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Processing...")
                }
            } else {
                Text("Generate Subtitles")
            }
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(videoProcessor.currentJob?.status.isProcessing == true ? Color.gray : Color.purple)
        .cornerRadius(16)
        .disabled(videoProcessor.currentJob?.status.isProcessing == true)
    }

    private var processingStatusCard: some View {
        VStack(spacing: 16) {
            ProgressView(value: videoProcessor.progress)
                .tint(.purple)

            Text(videoProcessor.statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Cancel", role: .destructive) {
                Task {
                    await videoProcessor.cancelJob()
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func resultCard(job: VideoJob) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Subtitles Generated!")
                .font(.title2.bold())

            if let transcription = job.transcription {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcription")
                        .font(.headline)

                    Text(transcription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let resultURL = job.resultVideoURL {
                NavigationLink(destination: VideoPlayerView(videoURL: URL(fileURLWithPath: resultURL))) {
                    Text("View Result")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.purple)
                        .cornerRadius(12)
                }
            }

            Button("Process Another Video") {
                selectedVideoURL = nil
                selectedVideoItem = nil
                videoProcessor.currentJob = nil
            }
            .font(.subheadline)
            .foregroundColor(.purple)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Actions

    private func loadVideo(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            guard let movie = try await item.loadTransferable(type: VideoFile.self) else { return }
            selectedVideoURL = movie.url
        } catch {
            errorMessage = "Failed to load video: \(error.localizedDescription)"
            showError = true
        }
    }

    private func processVideo() {
        guard let videoURL = selectedVideoURL else { return }

        // Check credits
        Task {
            do {
                let videoInfo = try await getVideoDuration(videoURL)
                let requiredCredits = creditManager.calculateRequiredCredits(for: videoInfo)

                if !creditManager.hasEnoughCredits(for: videoInfo) {
                    showPaywall = true
                    return
                }

                // Process video
                _ = try await videoProcessor.processVideo(
                    from: videoURL,
                    language: language,
                    fontName: fontName,
                    fontSize: fontSize,
                    fontColor: fontColor,
                    highlightColor: highlightColor,
                    position: position
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func getVideoDuration(_ url: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }
}

// MARK: - Supporting Types

struct VideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "import.\(received.file.pathExtension)")
            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

struct VideoPlayerView: View {
    let videoURL: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
            .ignoresSafeArea()
    }
}

#Preview {
    HomeView()
        .environmentObject(CreditManager.shared)
        .environmentObject(VideoProcessor.shared)
        .environmentObject(UserManager.shared)
}
