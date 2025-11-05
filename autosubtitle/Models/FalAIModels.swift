//
//  FalAIModels.swift
//  AutoSubtitle
//
//  API models for fal.ai auto-subtitle service
//

import Foundation

// MARK: - Request Models

struct FalAISubtitleRequest: Codable {
    let videoUrl: String
    let language: String?
    let fontName: String?
    let fontSize: Int?
    let fontWeight: String?
    let fontColor: String?
    let highlightColor: String?
    let strokeWidth: Int?
    let strokeColor: String?
    let backgroundColor: String?
    let backgroundOpacity: Double?
    let position: String?
    let wordsPerSubtitle: Int?
    let enableAnimation: Bool?

    enum CodingKeys: String, CodingKey {
        case videoUrl = "video_url"
        case language
        case fontName = "font_name"
        case fontSize = "font_size"
        case fontWeight = "font_weight"
        case fontColor = "font_color"
        case highlightColor = "highlight_color"
        case strokeWidth = "stroke_width"
        case strokeColor = "stroke_color"
        case backgroundColor = "background_color"
        case backgroundOpacity = "background_opacity"
        case position
        case wordsPerSubtitle = "words_per_subtitle"
        case enableAnimation = "enable_animation"
    }

    init(
        videoUrl: String,
        language: String? = "en",
        fontName: String? = "Montserrat",
        fontSize: Int? = 100,
        fontWeight: String? = "bold",
        fontColor: String? = "#FFFFFF",
        highlightColor: String? = "#A855F7",
        strokeWidth: Int? = 3,
        strokeColor: String? = "#000000",
        backgroundColor: String? = nil,
        backgroundOpacity: Double? = nil,
        position: String? = "bottom",
        wordsPerSubtitle: Int? = 3,
        enableAnimation: Bool? = true
    ) {
        self.videoUrl = videoUrl
        self.language = language
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontColor = fontColor
        self.highlightColor = highlightColor
        self.strokeWidth = strokeWidth
        self.strokeColor = strokeColor
        self.backgroundColor = backgroundColor
        self.backgroundOpacity = backgroundOpacity
        self.position = position
        self.wordsPerSubtitle = wordsPerSubtitle
        self.enableAnimation = enableAnimation
    }
}

// MARK: - Response Models

struct FalAIQueueResponse: Codable {
    let requestId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case status
    }
}

struct FalAIStatusResponse: Codable {
    let status: String
    let responseUrl: String?
    let logs: [FalAILogEntry]?

    enum CodingKeys: String, CodingKey {
        case status
        case responseUrl = "response_url"
        case logs
    }

    var falStatus: FalAIStatus {
        FalAIStatus(rawValue: status.uppercased()) ?? .unknown
    }
}

struct FalAILogEntry: Codable {
    let message: String
    let timestamp: String
    let level: String
}

struct FalAIResultResponse: Codable {
    let video: FalAIVideoFile?
    let transcription: String?
    let subtitleCount: Int?

    enum CodingKeys: String, CodingKey {
        case video
        case transcription
        case subtitleCount = "subtitle_count"
    }
}

struct FalAIVideoFile: Codable {
    let url: String
    let contentType: String?
    let fileName: String?
    let fileSize: Int64?

    enum CodingKeys: String, CodingKey {
        case url
        case contentType = "content_type"
        case fileName = "file_name"
        case fileSize = "file_size"
    }
}

struct FalAIErrorResponse: Codable {
    let error: String?
    let message: String?
    let detail: String?

    var errorMessage: String {
        error ?? message ?? detail ?? "Unknown error occurred"
    }
}

enum FalAIStatus: String {
    case inQueue = "IN_QUEUE"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
    case unknown = "UNKNOWN"

    var displayName: String {
        switch self {
        case .inQueue: return "In Queue"
        case .inProgress: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .unknown: return "Unknown"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .inQueue, .inProgress, .unknown:
            return false
        }
    }
}

// MARK: - Upload Models

struct FalAIUploadResponse: Codable {
    let uploadUrl: String
    let fileUrl: String

    enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case fileUrl = "file_url"
    }
}
