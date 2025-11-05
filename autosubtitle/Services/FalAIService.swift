//
//  FalAIService.swift
//  AutoSubtitle
//
//  Service for interacting with fal.ai auto-subtitle API
//

import Foundation

class FalAIService {
    static let shared = FalAIService()

    private let baseURL = "https://queue.fal.run"
    private let endpoint = "/fal-ai/workflow-utilities/auto-subtitle"
    private var apiKey: String = ""

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 600 // 10 minutes
        return URLSession(configuration: config)
    }()

    private init() {
        // Load API key from configuration
        if let key = Bundle.main.object(forInfoDictionaryKey: "FAL_API_KEY") as? String {
            self.apiKey = key
        }
    }

    func setAPIKey(_ key: String) {
        self.apiKey = key
    }

    // MARK: - File Upload

    /// Upload video file to fal.ai storage
    func uploadVideo(from localURL: URL) async throws -> String {
        // Get upload URL
        let uploadURLEndpoint = "\(baseURL)/storage/upload"

        var request = URLRequest(url: URL(string: uploadURLEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Get file info
        let fileData = try Data(contentsOf: localURL)
        let fileName = localURL.lastPathComponent
        let contentType = mimeType(for: localURL.pathExtension)

        let uploadRequestBody: [String: Any] = [
            "file_name": fileName,
            "content_type": contentType
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: uploadRequestBody)

        print("📤 Requesting upload URL for: \(fileName)")

        let (uploadData, uploadResponse) = try await session.data(for: request)

        guard let httpResponse = uploadResponse as? HTTPURLResponse else {
            throw FalAIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(FalAIErrorResponse.self, from: uploadData) {
                throw FalAIError.apiError(errorResponse.errorMessage)
            }
            throw FalAIError.uploadFailed("HTTP \(httpResponse.statusCode)")
        }

        let uploadResponse = try JSONDecoder().decode(FalAIUploadResponse.self, from: uploadData)

        // Upload file to the pre-signed URL
        var uploadFileRequest = URLRequest(url: URL(string: uploadResponse.uploadUrl)!)
        uploadFileRequest.httpMethod = "PUT"
        uploadFileRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        uploadFileRequest.httpBody = fileData

        print("📤 Uploading file to storage...")

        let (_, fileUploadResponse) = try await session.data(for: uploadFileRequest)

        guard let fileHttpResponse = fileUploadResponse as? HTTPURLResponse,
              (200...299).contains(fileHttpResponse.statusCode) else {
            throw FalAIError.uploadFailed("Failed to upload file")
        }

        print("✅ Video uploaded successfully: \(uploadResponse.fileUrl)")
        return uploadResponse.fileUrl
    }

    // MARK: - Submit Request

    /// Submit subtitle generation request
    func submitRequest(_ request: FalAISubtitleRequest) async throws -> String {
        let submitURL = URL(string: "\(baseURL)\(endpoint)")!

        var urlRequest = URLRequest(url: submitURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)

        print("📤 Submitting subtitle request for: \(request.videoUrl)")

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FalAIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(FalAIErrorResponse.self, from: data) {
                throw FalAIError.apiError(errorResponse.errorMessage)
            }
            throw FalAIError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let queueResponse = try decoder.decode(FalAIQueueResponse.self, from: data)

        print("✅ Request submitted. Request ID: \(queueResponse.requestId)")
        return queueResponse.requestId
    }

    // MARK: - Check Status

    /// Check the status of a request
    func checkStatus(requestId: String) async throws -> FalAIStatusResponse {
        let statusURL = URL(string: "\(baseURL)\(endpoint)/requests/\(requestId)/status")!

        var request = URLRequest(url: statusURL)
        request.httpMethod = "GET"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FalAIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(FalAIErrorResponse.self, from: data) {
                throw FalAIError.apiError(errorResponse.errorMessage)
            }
            throw FalAIError.statusCheckFailed("HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let statusResponse = try decoder.decode(FalAIStatusResponse.self, from: data)

        return statusResponse
    }

    // MARK: - Get Result

    /// Retrieve the result of a completed request
    func getResult(requestId: String) async throws -> FalAIResultResponse {
        let resultURL = URL(string: "\(baseURL)\(endpoint)/requests/\(requestId)")!

        var request = URLRequest(url: resultURL)
        request.httpMethod = "GET"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FalAIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(FalAIErrorResponse.self, from: data) {
                throw FalAIError.apiError(errorResponse.errorMessage)
            }
            throw FalAIError.resultFetchFailed("HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(FalAIResultResponse.self, from: data)

        print("✅ Result retrieved successfully")
        return result
    }

    // MARK: - Cancel Request

    /// Cancel a running request
    func cancelRequest(requestId: String) async throws {
        let cancelURL = URL(string: "\(baseURL)\(endpoint)/requests/\(requestId)/cancel")!

        var request = URLRequest(url: cancelURL)
        request.httpMethod = "PUT"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FalAIError.cancelFailed("Failed to cancel request")
        }

        print("✅ Request cancelled: \(requestId)")
    }

    // MARK: - Download Video

    /// Download the result video
    func downloadVideo(from url: String, to localURL: URL) async throws {
        guard let videoURL = URL(string: url) else {
            throw FalAIError.invalidURL
        }

        let (tempURL, response) = try await session.download(from: videoURL)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FalAIError.downloadFailed("Failed to download video")
        }

        // Move to final location
        try FileManager.default.moveItem(at: tempURL, to: localURL)

        print("✅ Video downloaded to: \(localURL.path)")
    }

    // MARK: - Helper Methods

    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "m4v": return "video/x-m4v"
        case "webm": return "video/webm"
        case "gif": return "image/gif"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Error Types

enum FalAIError: LocalizedError, Identifiable {
    case invalidURL
    case invalidResponse
    case uploadFailed(String)
    case requestFailed(String)
    case statusCheckFailed(String)
    case resultFetchFailed(String)
    case cancelFailed(String)
    case downloadFailed(String)
    case apiError(String)
    case timeout

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .statusCheckFailed(let message):
            return "Status check failed: \(message)"
        case .resultFetchFailed(let message):
            return "Failed to fetch result: \(message)"
        case .cancelFailed(let message):
            return "Cancel failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .timeout:
            return "Request timed out"
        }
    }
}
