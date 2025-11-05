# Configuration Guide - AutoSubtitle

Detailed configuration guide for all services and features.

## Table of Contents

1. [Firebase Configuration](#firebase-configuration)
2. [RevenueCat Setup](#revenuecat-setup)
3. [fal.ai API Configuration](#falai-api-configuration)
4. [Xcode Project Settings](#xcode-project-settings)
5. [Environment Variables](#environment-variables)
6. [Feature Flags](#feature-flags)

## Firebase Configuration

### 1. Create Firebase Project

```bash
# Visit Firebase Console
https://console.firebase.google.com

# Create project steps:
1. Click "Add project"
2. Enter project name: "AutoSubtitle"
3. Enable Google Analytics: Yes (recommended)
4. Choose or create Analytics account
5. Click "Create project"
```

### 2. Add iOS App

```bash
# In Firebase Console
1. Click iOS icon
2. iOS bundle ID: com.yourcompany.autosubtitle
3. App nickname: AutoSubtitle Production
4. App Store ID: (leave empty for now)
5. Download GoogleService-Info.plist
```

### 3. Add GoogleService-Info.plist to Xcode

```bash
# Method 1: Drag and drop
1. Download GoogleService-Info.plist
2. Drag into Xcode project navigator
3. Select "Copy items if needed"
4. Add to target: AutoSubtitle

# Method 2: Terminal
cp ~/Downloads/GoogleService-Info.plist ./AutoSubtitle/Resources/
```

### 4. Enable Authentication

```bash
# In Firebase Console → Authentication
1. Click "Get Started"
2. Go to "Sign-in method" tab
3. Enable "Anonymous"
4. Click "Save"
```

### 5. Create Firestore Database

```bash
# In Firebase Console → Firestore Database
1. Click "Create database"
2. Start in "production mode"
3. Select location: us-central1 (or your preferred region)
4. Click "Enable"
```

### 6. Configure Firestore Indexes

Create composite indexes for queries:

```javascript
// In Firebase Console → Firestore → Indexes
// Create these composite indexes:

// Index 1: User jobs by date
Collection: users/{userId}/jobs
Fields indexed:
  - userId: Ascending
  - createdAt: Descending
  - status: Ascending

// Index 2: User transactions by date
Collection: users/{userId}/transactions
Fields indexed:
  - userId: Ascending
  - timestamp: Descending
  - type: Ascending
```

### 7. Set Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId) &&
                       !request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['firebaseUID']);

      // Transactions subcollection
      match /transactions/{transactionId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId) &&
                         request.resource.data.userId == userId &&
                         request.resource.data.timestamp is timestamp;
        allow update, delete: if false; // Transactions are immutable
      }

      // Jobs subcollection
      match /jobs/{jobId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId) && request.resource.data.userId == userId;
        allow update: if isOwner(userId) &&
                         request.resource.data.userId == resource.data.userId;
        allow delete: if isOwner(userId);
      }
    }
  }
}
```

### 8. Enable Analytics (Optional)

```bash
# In Firebase Console → Analytics
1. Analytics is automatically enabled
2. Navigate to "Events" tab
3. Mark important events as conversion events:
   - purchase
   - video_processed
   - subscription_started
```

### 9. Firebase Cloud Messaging (Optional)

```bash
# For push notifications (future feature)
1. In Firebase Console → Cloud Messaging
2. Upload APNs certificate or key
3. Note Server Key for backend
```

## RevenueCat Setup

### 1. Create Account

```bash
# Sign up
https://app.revenuecat.com/signup

# Email verification required
```

### 2. Create Project

```bash
# In RevenueCat Dashboard
1. Click "Create new project"
2. Project name: AutoSubtitle
3. Click "Create"
```

### 3. Add App

```bash
# In project dashboard
1. Click "Add app"
2. Platform: iOS
3. App name: AutoSubtitle
4. Bundle ID: com.yourcompany.autosubtitle
5. Apple App ID: (from App Store Connect, format: 1234567890)
```

### 4. Configure App Store Connect Integration

#### Option A: App Store Connect API Key (Recommended)

```bash
# In App Store Connect
1. Users and Access → Keys → App Store Connect API
2. Click "+" to create key
3. Name: RevenueCat Integration
4. Access: Admin or App Manager
5. Download .p8 file
6. Note: Key ID and Issuer ID

# In RevenueCat
1. App Settings → Service credentials
2. Upload .p8 file
3. Enter Key ID and Issuer ID
4. Click "Save"
```

#### Option B: Shared Secret

```bash
# In App Store Connect
1. My Apps → [Your App] → General → App Information
2. App-Specific Shared Secret → Manage
3. Generate new secret
4. Copy secret

# In RevenueCat
1. App Settings → Service credentials
2. Paste shared secret
3. Click "Save"
```

### 5. Create Products

#### Subscriptions

```bash
# In App Store Connect first
1. My Apps → [Your App] → Features → In-App Purchases
2. Click "+" → Auto-Renewable Subscription
3. Create subscription group: "Premium Plans"

# Product 1: Starter
Reference Name: Starter Monthly Subscription
Product ID: com.autosubtitle.subscription.starter.monthly
Subscription Group: Premium Plans
Subscription Duration: 1 Month
Price: $9.99

# Product 2: Pro
Reference Name: Pro Monthly Subscription
Product ID: com.autosubtitle.subscription.pro.monthly
Subscription Group: Premium Plans
Subscription Duration: 1 Month
Price: $24.99

# Product 3: Ultimate
Reference Name: Ultimate Monthly Subscription
Product ID: com.autosubtitle.subscription.ultimate.monthly
Subscription Group: Premium Plans
Subscription Duration: 1 Month
Price: $49.99

# Then in RevenueCat
1. Products → Create new product
2. Enter Product ID (must match App Store Connect)
3. Select product type: Subscription
4. Link to App Store product
5. Set display name and description
```

#### One-Time Purchases (Consumables)

```bash
# In App Store Connect
1. Click "+" → Consumable

# Small Pack
Reference Name: Small Credit Pack
Product ID: com.autosubtitle.credits.small
Price: $4.99

# Medium Pack
Reference Name: Medium Credit Pack
Product ID: com.autosubtitle.credits.medium
Price: $14.99

# Large Pack
Reference Name: Large Credit Pack
Product ID: com.autosubtitle.credits.large
Price: $39.99

# In RevenueCat
1. Create products matching App Store
2. Set type: Consumable
```

### 6. Create Offerings

```bash
# In RevenueCat Dashboard → Offerings
1. Click "Create new offering"
2. Identifier: default
3. Description: Default offering

# Add packages
Package 1:
  - Identifier: starter_monthly
  - Product: com.autosubtitle.subscription.starter.monthly
  - Display name: Starter

Package 2:
  - Identifier: pro_monthly
  - Product: com.autosubtitle.subscription.pro.monthly
  - Display name: Pro

Package 3:
  - Identifier: ultimate_monthly
  - Product: com.autosubtitle.subscription.ultimate.monthly
  - Display name: Ultimate

# Create "credits" offering
Offering 2:
  - Identifier: credits
  - Description: Credit packs
  - Add consumable products
```

### 7. Configure Entitlements

```bash
# In RevenueCat → Entitlements
1. Click "Create new entitlement"
2. Identifier: premium
3. Display name: Premium Features
4. Attach products: All subscription products
```

### 8. Get API Key

```bash
# In RevenueCat Dashboard
1. Project settings → API keys
2. Click "Show key"
3. Copy public API key (starts with "appl_" or "goog_")
4. For iOS use the Apple SDK key
```

### 9. Configure Webhooks (Optional)

```bash
# In RevenueCat → Integrations → Webhooks
URL: https://your-backend.com/webhooks/revenuecat
Authorization Header: Bearer YOUR_SECRET_TOKEN

Events to subscribe:
- INITIAL_PURCHASE
- RENEWAL
- CANCELLATION
- NON_RENEWING_PURCHASE
- EXPIRATION
```

## fal.ai API Configuration

### 1. Create Account

```bash
# Sign up
https://fal.ai/signup

# Verify email
```

### 2. Get API Key

```bash
# In fal.ai Dashboard
1. Navigate to API Keys
2. Click "Create new key"
3. Name: AutoSubtitle Production
4. Permissions: Read & Write
5. Copy key (starts with "fal_")
```

### 3. Test API

```bash
# Test with curl
curl -X POST "https://queue.fal.run/fal-ai/workflow-utilities/auto-subtitle" \
  -H "Authorization: Key YOUR_FAL_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "video_url": "https://example.com/test.mp4",
    "language": "en"
  }'
```

### 4. Monitor Usage

```bash
# In fal.ai Dashboard
1. Navigate to Usage
2. Monitor API calls
3. Set up billing alerts
4. Review cost per request
```

### 5. Rate Limits

```
Free tier:
- 100 requests/day
- 1 request/second

Pro tier:
- Unlimited requests
- 10 requests/second
- Priority processing
```

## Xcode Project Settings

### 1. Basic Settings

```swift
// Project Settings
Product Name: AutoSubtitle
Organization: Your Company
Bundle Identifier: com.yourcompany.autosubtitle
Version: 1.0.0
Build: 1

// Deployment Info
iOS Deployment Target: 15.0
iPhone Only
Portrait orientation only
```

### 2. Signing & Capabilities

```swift
// Signing
Team: [Your Team]
Signing Certificate: Apple Development (Debug) / Apple Distribution (Release)
Provisioning Profile: Automatic

// Capabilities to add:
- Push Notifications (optional, for future)
- In-App Purchase
- Background Modes → Background fetch (optional)
```

### 3. Build Settings

```swift
// Swift Compiler
Swift Language Version: Swift 5
Compilation Mode: Whole Module (Release)
Optimization Level: -O (Release)

// Linking
Other Linker Flags: $(inherited) -ObjC

// Search Paths
Header Search Paths: $(inherited)
Library Search Paths: $(inherited)

// Code Signing
Code Signing Identity: Apple Development (Debug) / Apple Distribution (Release)
```

### 4. Info.plist Configuration

```xml
<!-- Required Permissions -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to select videos for subtitle generation</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save processed videos to your library</string>

<key>NSCameraUsageDescription</key>
<string>We need camera access to record videos for subtitling</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record audio for transcription</string>

<!-- App Configuration -->
<key>CFBundleDisplayName</key>
<string>AutoSubtitle</string>

<key>UILaunchScreen</key>
<dict>
    <key>UIImageName</key>
    <string>LaunchIcon</string>
    <key>UIColorName</key>
    <string>LaunchBackground</string>
</dict>

<!-- URL Schemes (optional) -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>autosubtitle</string>
        </array>
    </dict>
</array>

<!-- Firebase Configuration -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>

<!-- API Keys (use Config.plist in production) -->
<key>REVENUECAT_API_KEY</key>
<string>$(REVENUECAT_API_KEY)</string>

<key>FAL_API_KEY</key>
<string>$(FAL_API_KEY)</string>
```

### 5. Package Dependencies

Add these Swift Package dependencies:

```swift
// Firebase SDK
https://github.com/firebase/firebase-ios-sdk
- FirebaseAuth
- FirebaseFirestore
- FirebaseAnalytics
- FirebaseCrashlytics (optional)

// RevenueCat SDK
https://github.com/RevenueCat/purchases-ios
- RevenueCat
```

## Environment Variables

### Development

Create `.env.development`:

```bash
# Firebase
FIREBASE_PROJECT_ID=autosubtitle-dev
FIREBASE_API_KEY=your-dev-key

# RevenueCat
REVENUECAT_API_KEY=appl_xxxxxxxxx

# fal.ai
FAL_API_KEY=fal_xxxxxxxxx

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=false
DEBUG_MODE=true
```

### Production

Create `.env.production`:

```bash
# Firebase
FIREBASE_PROJECT_ID=autosubtitle-prod
FIREBASE_API_KEY=your-prod-key

# RevenueCat
REVENUECAT_API_KEY=appl_xxxxxxxxx

# fal.ai
FAL_API_KEY=fal_xxxxxxxxx

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
DEBUG_MODE=false
```

### Loading Environment Variables

```swift
// Create Config.swift
import Foundation

enum Config {
    static let revenueCatAPIKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""
    }()

    static let falAPIKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "FAL_API_KEY") as? String ?? ""
    }()

    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
```

## Feature Flags

### Implementation

```swift
// FeatureFlags.swift
enum FeatureFlags {
    // Features
    static let enableSubscriptions = true
    static let enableOneTimePurchases = true
    static let enableVideoEditing = false // Future feature
    static let enableBatchProcessing = false // Pro only

    // Debug
    static let enableDebugMenu = Config.isDebugMode
    static let enableMockPurchases = Config.isDebugMode

    // Analytics
    static let enableAnalytics = true
    static let enableCrashReporting = !Config.isDebugMode

    // API
    static let apiTimeout: TimeInterval = 120
    static let maxRetries = 3
    static let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB

    // Credits
    static let freeUserStartingCredits = 5
    static let creditsPerMinute = 1
}
```

### Usage

```swift
// In code
if FeatureFlags.enableSubscriptions {
    // Show subscription UI
}

if FeatureFlags.enableDebugMenu {
    // Show debug options
}
```

## Validation

### Validate Configuration

```swift
// ValidateConfiguration.swift
func validateConfiguration() {
    // Check API keys
    assert(!Config.revenueCatAPIKey.isEmpty, "RevenueCat API key missing")
    assert(!Config.falAPIKey.isEmpty, "fal.ai API key missing")

    // Check Firebase
    assert(FirebaseApp.app() != nil, "Firebase not configured")

    // Check bundle ID
    let bundleID = Bundle.main.bundleIdentifier
    assert(bundleID != nil && bundleID!.hasPrefix("com."), "Invalid bundle ID")

    print("✅ Configuration validated successfully")
}

// Call in AppDelegate or App init
#if DEBUG
validateConfiguration()
#endif
```

---

## Troubleshooting

### Firebase Issues

```bash
# GoogleService-Info.plist not found
Solution: Ensure file is added to project target

# Authentication fails
Solution: Enable Anonymous authentication in Firebase Console

# Firestore permission denied
Solution: Check security rules
```

### RevenueCat Issues

```bash
# Products not loading
Solution: Wait 15 minutes after creating products in App Store Connect
         Verify products are "Ready to Submit" status
         Check RevenueCat dashboard for product sync

# Purchases failing
Solution: Test with sandbox account
         Verify service credentials in RevenueCat
         Check App Store Connect agreements
```

### fal.ai Issues

```bash
# API key invalid
Solution: Regenerate API key in fal.ai dashboard
         Check key format (should start with "fal_")

# Upload fails
Solution: Check video file size (max 100MB)
         Verify video format (mp4, mov, webm, m4v, gif)
         Check network connectivity
```

---

**Need help?** Contact support@autosubtitle.app
