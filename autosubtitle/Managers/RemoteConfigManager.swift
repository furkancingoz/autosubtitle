//
//  RemoteConfigManager.swift
//  AutoSubtitle
//
//  Firebase Remote Config manager for API keys and feature flags
//

import Foundation
import FirebaseRemoteConfig
import Combine

class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()

    @Published var isConfigFetched = false
    @Published var error: ConfigError?

    private let remoteConfig: RemoteConfig
    private let defaults: [String: NSObject] = [
        // API Keys (defaults - will be overridden by Remote Config)
        "revenuecat_api_key": "" as NSObject,
        "fal_api_key": "" as NSObject,

        // Feature Flags
        "enable_subscriptions": true as NSObject,
        "enable_one_time_purchases": true as NSObject,
        "enable_video_editing": false as NSObject,
        "enable_batch_processing": false as NSObject,

        // Limits
        "max_video_size_mb": 100 as NSObject,
        "max_video_duration_minutes": 60 as NSObject,
        "free_user_credits": 5 as NSObject,
        "max_retries": 3 as NSObject,

        // Pricing (for display purposes)
        "starter_monthly_credits": 60 as NSObject,
        "pro_monthly_credits": 180 as NSObject,
        "ultimate_monthly_credits": 500 as NSObject
    ]

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()

        // Configure fetch settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour in production
        #if DEBUG
        settings.minimumFetchInterval = 0 // No cache in debug
        #endif

        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(defaults)
    }

    // MARK: - Fetch Configuration

    func fetchConfig() async throws {
        do {
            let status = try await remoteConfig.fetch()
            print("📡 Remote Config fetch status: \(status)")

            try await remoteConfig.activate()

            DispatchQueue.main.async {
                self.isConfigFetched = true
            }

            print("✅ Remote Config activated successfully")
            logAllKeys()

        } catch {
            print("❌ Remote Config fetch failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.error = .fetchFailed(error.localizedDescription)
            }
            throw ConfigError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchConfigWithTimeout(timeout: TimeInterval = 10) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Fetch task
            group.addTask {
                try await self.fetchConfig()
            }

            // Timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw ConfigError.timeout
            }

            // Wait for first to complete
            try await group.next()
            group.cancelAll()
        }
    }

    // MARK: - API Keys

    var revenueCatAPIKey: String {
        let key = remoteConfig.configValue(forKey: "revenuecat_api_key").stringValue

        #if DEBUG
        if key?.isEmpty ?? true {
            print("⚠️ RevenueCat API key not configured in Remote Config")
        }
        #endif

        return key ?? ""
    }

    var falAPIKey: String {
        let key = remoteConfig.configValue(forKey: "fal_api_key").stringValue

        #if DEBUG
        if key?.isEmpty ?? true {
            print("⚠️ fal.ai API key not configured in Remote Config")
        }
        #endif

        return key ?? ""
    }

    // MARK: - Feature Flags

    var enableSubscriptions: Bool {
        remoteConfig.configValue(forKey: "enable_subscriptions").boolValue
    }

    var enableOneTimePurchases: Bool {
        remoteConfig.configValue(forKey: "enable_one_time_purchases").boolValue
    }

    var enableVideoEditing: Bool {
        remoteConfig.configValue(forKey: "enable_video_editing").boolValue
    }

    var enableBatchProcessing: Bool {
        remoteConfig.configValue(forKey: "enable_batch_processing").boolValue
    }

    // MARK: - Limits

    var maxVideoSizeMB: Int {
        Int(remoteConfig.configValue(forKey: "max_video_size_mb").numberValue.intValue)
    }

    var maxVideoSizeBytes: Int64 {
        Int64(maxVideoSizeMB) * 1024 * 1024
    }

    var maxVideoDurationMinutes: Int {
        Int(remoteConfig.configValue(forKey: "max_video_duration_minutes").numberValue.intValue)
    }

    var maxVideoDurationSeconds: TimeInterval {
        TimeInterval(maxVideoDurationMinutes * 60)
    }

    var freeUserCredits: Int {
        Int(remoteConfig.configValue(forKey: "free_user_credits").numberValue.intValue)
    }

    var maxRetries: Int {
        Int(remoteConfig.configValue(forKey: "max_retries").numberValue.intValue)
    }

    // MARK: - Pricing

    var starterMonthlyCredits: Int {
        Int(remoteConfig.configValue(forKey: "starter_monthly_credits").numberValue.intValue)
    }

    var proMonthlyCredits: Int {
        Int(remoteConfig.configValue(forKey: "pro_monthly_credits").numberValue.intValue)
    }

    var ultimateMonthlyCredits: Int {
        Int(remoteConfig.configValue(forKey: "ultimate_monthly_credits").numberValue.intValue)
    }

    // MARK: - Validation

    func validateConfiguration() -> Bool {
        var isValid = true
        var issues: [String] = []

        // Check API keys
        if revenueCatAPIKey.isEmpty {
            issues.append("RevenueCat API key is missing")
            isValid = false
        }

        if falAPIKey.isEmpty {
            issues.append("fal.ai API key is missing")
            isValid = false
        }

        // Check limits
        if maxVideoSizeMB <= 0 {
            issues.append("Invalid max video size")
            isValid = false
        }

        if maxVideoDurationMinutes <= 0 {
            issues.append("Invalid max video duration")
            isValid = false
        }

        if !isValid {
            print("❌ Configuration validation failed:")
            issues.forEach { print("  - \($0)") }
        } else {
            print("✅ Configuration validated successfully")
        }

        return isValid
    }

    // MARK: - Debug

    private func logAllKeys() {
        #if DEBUG
        print("📋 Remote Config values:")
        print("  RevenueCat API Key: \(revenueCatAPIKey.isEmpty ? "NOT SET" : "SET (\(revenueCatAPIKey.prefix(10))...)")")
        print("  fal.ai API Key: \(falAPIKey.isEmpty ? "NOT SET" : "SET (\(falAPIKey.prefix(10))...)")")
        print("  Enable Subscriptions: \(enableSubscriptions)")
        print("  Enable One-Time Purchases: \(enableOneTimePurchases)")
        print("  Max Video Size: \(maxVideoSizeMB) MB")
        print("  Max Video Duration: \(maxVideoDurationMinutes) minutes")
        print("  Free User Credits: \(freeUserCredits)")
        print("  Max Retries: \(maxRetries)")
        #endif
    }

    // MARK: - Get Value (Generic)

    func getString(_ key: String, defaultValue: String = "") -> String {
        remoteConfig.configValue(forKey: key).stringValue ?? defaultValue
    }

    func getInt(_ key: String, defaultValue: Int = 0) -> Int {
        Int(remoteConfig.configValue(forKey: key).numberValue.intValue)
    }

    func getBool(_ key: String, defaultValue: Bool = false) -> Bool {
        remoteConfig.configValue(forKey: key).boolValue
    }

    func getDouble(_ key: String, defaultValue: Double = 0.0) -> Double {
        remoteConfig.configValue(forKey: key).numberValue.doubleValue
    }
}

// MARK: - Error Types

enum ConfigError: LocalizedError, Identifiable {
    case fetchFailed(String)
    case timeout
    case validationFailed

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch configuration: \(message)"
        case .timeout:
            return "Configuration fetch timed out"
        case .validationFailed:
            return "Configuration validation failed"
        }
    }
}
