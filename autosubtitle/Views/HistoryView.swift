//
//  HistoryView.swift
//  AutoSubtitle
//
//  Video processing history
//

import SwiftUI
import FirebaseFirestore

struct HistoryView: View {
    @EnvironmentObject var userManager: UserManager

    @State private var jobs: [VideoJob] = []
    @State private var isLoading = false
    @State private var selectedFilter: JobFilter = .all

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter
                filterSection

                // Job List
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredJobs.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredJobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobRow(job: job)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .task {
                await loadJobs()
            }
            .refreshable {
                await loadJobs()
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredJobs: [VideoJob] {
        switch selectedFilter {
        case .all:
            return jobs
        case .completed:
            return jobs.filter { $0.status == .completed }
        case .processing:
            return jobs.filter { $0.status.isProcessing }
        case .failed:
            return jobs.filter { $0.status == .failed || $0.status == .error }
        }
    }

    // MARK: - Components

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(JobFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        count: jobCount(for: filter)
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Videos Yet")
                .font(.title2.bold())

            Text("Your processed videos will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadJobs() async {
        guard let userId = FirebaseAuthManager.shared.userId else { return }

        isLoading = true

        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("jobs")
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()

            jobs = try snapshot.documents.compactMap { doc in
                try doc.data(as: VideoJob.self)
            }
        } catch {
            print("❌ Failed to load jobs: \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func jobCount(for filter: JobFilter) -> Int {
        switch filter {
        case .all:
            return jobs.count
        case .completed:
            return jobs.filter { $0.status == .completed }.count
        case .processing:
            return jobs.filter { $0.status.isProcessing }.count
        case .failed:
            return jobs.filter { $0.status == .failed || $0.status == .error }.count
        }
    }
}

// MARK: - Job Filter

enum JobFilter: String, CaseIterable {
    case all = "All"
    case completed = "Completed"
    case processing = "Processing"
    case failed = "Failed"
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())

                if count > 0 {
                    Text("\(count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.purple.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

// MARK: - Job Row

struct JobRow: View {
    let job: VideoJob

    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: job.statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(job.videoFileName)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(job.status.displayName)
                        .font(.caption)
                        .foregroundColor(statusColor)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(job.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let transcription = job.transcription {
                    Text(transcription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Credits & Arrow
            VStack(alignment: .trailing, spacing: 4) {
                if job.creditsDeducted > 0 {
                    Text("-\(job.creditsDeducted)")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                }

                if job.creditsRefunded > 0 {
                    Text("+\(job.creditsRefunded)")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch job.status {
        case .completed:
            return .green
        case .failed, .error:
            return .red
        case .processing, .uploading, .queued, .downloading:
            return .blue
        case .cancelled:
            return .orange
        default:
            return .secondary
        }
    }
}

// MARK: - Job Detail View

struct JobDetailView: View {
    let job: VideoJob

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status
                HStack {
                    Image(systemName: job.statusIcon)
                        .font(.title)
                        .foregroundColor(statusColor)

                    Text(job.status.displayName)
                        .font(.title2.bold())

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Details
                detailsSection

                // Transcription
                if let transcription = job.transcription {
                    transcriptionSection(transcription)
                }

                // Error
                if let error = job.errorMessage {
                    errorSection(error)
                }

                // Result Video
                if let resultPath = job.resultVideoURL,
                   let resultURL = URL(string: resultPath) {
                    resultSection(resultURL)
                }
            }
            .padding()
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            DetailRow(label: "File Name", value: job.videoFileName)
            DetailRow(label: "Duration", value: String(format: "%.1fs", job.videoDuration))
            DetailRow(label: "Credits Used", value: "\(job.creditsDeducted)")

            if job.creditsRefunded > 0 {
                DetailRow(label: "Credits Refunded", value: "\(job.creditsRefunded)")
            }

            DetailRow(label: "Created", value: job.createdAt.formatted(date: .long, time: .shortened))

            if let completed = job.completedAt {
                DetailRow(label: "Completed", value: completed.formatted(date: .long, time: .shortened))
            }

            if let processingTime = job.processingTime {
                DetailRow(label: "Processing Time", value: String(format: "%.1fs", processingTime))
            }

            if let count = job.subtitleCount {
                DetailRow(label: "Subtitle Count", value: "\(count)")
            }

            DetailRow(label: "Language", value: job.language)
            DetailRow(label: "Retry Count", value: "\(job.retryCount)/\(job.maxRetries)")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func transcriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcription")
                .font(.headline)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)

                Text("Error")
                    .font(.headline)
            }

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    private func resultSection(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Result")
                .font(.headline)

            NavigationLink(destination: VideoPlayerView(videoURL: url)) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title)

                    Text("View Subtitled Video")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.purple)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    private var statusColor: Color {
        switch job.status {
        case .completed:
            return .green
        case .failed, .error:
            return .red
        case .processing, .uploading, .queued, .downloading:
            return .blue
        case .cancelled:
            return .orange
        default:
            return .secondary
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .font(.subheadline)
    }
}

#Preview {
    HistoryView()
        .environmentObject(UserManager.shared)
}
