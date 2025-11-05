# AutoSubtitle - AI-Powered Video Subtitle Generator

<div align="center">

![AutoSubtitle Logo](https://via.placeholder.com/150)

**Automatically generate beautiful, customizable subtitles for your videos using AI**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-yellow.svg)](https://firebase.google.com)
[![RevenueCat](https://img.shields.io/badge/RevenueCat-Latest-green.svg)](https://revenuecat.com)

</div>

## Overview

AutoSubtitle is a premium iOS application that leverages fal.ai's powerful AI technology to automatically generate accurate, stylish subtitles for videos. With a credit-based monetization system powered by RevenueCat and Firebase, users can easily process videos and customize subtitle appearance.

### Key Features

- **AI-Powered Transcription**: Automatic speech-to-text with word-level timing
- **Multi-Language Support**: Support for 50+ languages
- **Customizable Styling**: Multiple fonts, colors, positions, and animations
- **Credit System**: Flexible credit-based pricing with secure Keychain storage
- **Subscription Tiers**: Free, Starter, Pro, and Ultimate plans
- **Real-time Processing**: Queue-based processing with status updates
- **Error Handling**: Automatic retry with credit refunds on failure
- **Transaction History**: Complete credit and processing history
- **Anonymous Authentication**: Frictionless onboarding with Firebase
- **Professional UI**: Modern SwiftUI interface with smooth animations

## Architecture

Built with a modern MVVM architecture using SwiftUI, combining:

- **Frontend**: SwiftUI with iOS 15+ support
- **Backend Services**:
  - Firebase (Authentication & Firestore)
  - RevenueCat (In-App Purchases)
  - fal.ai (Video Subtitle Generation)
- **Local Storage**:
  - Keychain (Secure credit storage)
  - UserDefaults (Preferences)
  - FileManager (Video files)

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed system design.

## Prerequisites

Before you begin, ensure you have:

- macOS 13.0+ with Xcode 15.0+
- iOS 15.0+ device or simulator
- Active Apple Developer Account
- Firebase project
- RevenueCat account
- fal.ai API key

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/autosubtitle.git
cd autosubtitle
```

### 2. Install Dependencies

```bash
# Using Swift Package Manager (recommended)
# Dependencies will be automatically resolved when opening in Xcode

# Or manually add these packages in Xcode:
# - Firebase iOS SDK
# - RevenueCat SDK
```

### 3. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an iOS app to your project
3. Download `GoogleService-Info.plist`
4. Add it to your Xcode project
5. Enable Authentication (Anonymous provider)
6. Create Firestore database with these collections:
   - `users`
   - `users/{userId}/transactions`
   - `users/{userId}/jobs`

### 4. Configure RevenueCat

1. Create account at [revenuecat.com](https://revenuecat.com)
2. Create a new app
3. Configure products in App Store Connect:
   - `com.autosubtitle.subscription.starter.monthly`
   - `com.autosubtitle.subscription.pro.monthly`
   - `com.autosubtitle.subscription.ultimate.monthly`
   - `com.autosubtitle.credits.small`
   - `com.autosubtitle.credits.medium`
   - `com.autosubtitle.credits.large`
4. Link App Store Connect to RevenueCat
5. Copy your API key

### 5. Get fal.ai API Key

1. Sign up at [fal.ai](https://fal.ai)
2. Navigate to API Keys section
3. Create a new API key
4. Copy the key for configuration

### 6. Configure the App

Edit `AutoSubtitle/App/AutoSubtitleApp.swift`:

```swift
// Replace these with your actual keys
let revenueCatAPIKey = "YOUR_REVENUECAT_API_KEY"
let falAPIKey = "YOUR_FAL_API_KEY"
```

Or use a configuration file (recommended for production):

Create `Config.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>REVENUECAT_API_KEY</key>
    <string>YOUR_REVENUECAT_API_KEY</string>
    <key>FAL_API_KEY</key>
    <string>YOUR_FAL_API_KEY</string>
</dict>
</plist>
```

### 7. Build and Run

```bash
# Open in Xcode
open AutoSubtitle.xcodeproj

# Or use command line
xcodebuild -scheme AutoSubtitle -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Project Structure

```
AutoSubtitle/
├── App/
│   └── AutoSubtitleApp.swift       # Main app entry point
├── Models/
│   ├── User.swift                  # User data model
│   ├── VideoJob.swift              # Video processing job
│   ├── CreditTransaction.swift     # Transaction model
│   ├── PurchaseProduct.swift       # IAP products
│   └── FalAIModels.swift          # API models
├── Managers/
│   ├── FirebaseAuthManager.swift   # Authentication
│   ├── UserManager.swift           # User data management
│   ├── CreditManager.swift         # Credit operations
│   └── RevenueCatManager.swift     # IAP management
├── Services/
│   ├── FalAIService.swift         # fal.ai API client
│   └── VideoProcessor.swift       # Video processing orchestration
├── Views/
│   ├── MainTabView.swift          # Main navigation
│   ├── OnboardingView.swift       # First-launch onboarding
│   ├── HomeView.swift             # Video upload & processing
│   ├── PaywallView.swift          # Purchase screen
│   ├── CreditsView.swift          # Credit balance & history
│   ├── HistoryView.swift          # Processing history
│   └── SettingsView.swift         # App settings
└── Resources/
    └── Assets.xcassets            # Images and colors
```

## Configuration

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /transactions/{transactionId} {
        allow read: if request.auth != null && request.auth.uid == userId;
        allow write: if request.auth != null && request.auth.uid == userId;
      }

      match /jobs/{jobId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### RevenueCat Products

Configure these products in App Store Connect and RevenueCat:

**Subscriptions:**
- Starter: $9.99/month - 60 credits
- Pro: $24.99/month - 180 credits
- Ultimate: $49.99/month - 500 credits

**One-Time Purchases:**
- Small Pack: $4.99 - 20 credits
- Medium Pack: $14.99 - 75 credits
- Large Pack: $39.99 - 250 credits

### Environment Variables

For CI/CD, use environment variables:

```bash
export REVENUECAT_API_KEY="rc_xxx"
export FAL_API_KEY="xxx"
export FIREBASE_PROJECT_ID="your-project-id"
```

## Usage

### Basic Video Processing Flow

1. **Select Video**: User selects video from photo library
2. **Validate**: App validates video (size, duration, audio)
3. **Check Credits**: Verify user has enough credits
4. **Customize**: User chooses language, font, position
5. **Process**:
   - Deduct credits
   - Upload to fal.ai
   - Monitor processing status
   - Download result
6. **Complete**: Display result or refund credits on error

### Credit Management

```swift
// Check if user has enough credits
let requiredCredits = creditManager.calculateRequiredCredits(for: videoDuration)
let hasCredits = creditManager.hasEnoughCredits(for: videoDuration)

// Deduct credits
try await creditManager.deductCredits(
    amount,
    type: .deduction,
    reference: jobId,
    description: "Video processing"
)

// Refund credits on failure
try await creditManager.refundCredits(
    amount,
    reference: jobId,
    description: "Processing failed"
)
```

### Error Handling

The app includes comprehensive error handling:

- **Network Errors**: Automatic retry with exponential backoff
- **Validation Errors**: Pre-flight checks prevent wasted credits
- **Processing Failures**: Automatic credit refunds
- **Timeout Handling**: Max 10-minute processing time
- **User Cancellation**: Credits returned on cancel

## Testing

### Unit Tests

```bash
xcodebuild test -scheme AutoSubtitle -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Credit System

```swift
// Test credit deduction
func testCreditDeduction() async throws {
    let initialBalance = creditManager.creditBalance
    try await creditManager.deductCredits(5, type: .deduction)
    XCTAssertEqual(creditManager.creditBalance, initialBalance - 5)
}

// Test refund
func testCreditRefund() async throws {
    let initialBalance = creditManager.creditBalance
    try await creditManager.refundCredits(5, description: "Test refund")
    XCTAssertEqual(creditManager.creditBalance, initialBalance + 5)
}
```

### Test Purchase Flow

Use StoreKit Configuration file for testing IAP in development:

1. Create `StoreKitConfiguration.storekit`
2. Add test products
3. Enable in scheme settings

## Deployment

### App Store Submission

1. **Prepare Assets**:
   - App icon (1024x1024)
   - Screenshots for all device sizes
   - Privacy policy URL
   - Terms of service URL

2. **Configure App Store Connect**:
   - App description
   - Keywords
   - Categories
   - Age rating
   - In-app purchases

3. **Build Archive**:
   ```bash
   xcodebuild archive -scheme AutoSubtitle -archivePath build/AutoSubtitle.xcarchive
   ```

4. **Upload**:
   ```bash
   xcodebuild -exportArchive -archivePath build/AutoSubtitle.xcarchive -exportPath build/AutoSubtitle.ipa -exportOptionsPlist ExportOptions.plist
   ```

5. **Submit for Review**

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment guide.

## Monitoring & Analytics

### Firebase Analytics

Track key events:
- `app_open`
- `video_upload_started`
- `video_processing_completed`
- `credit_purchase`
- `subscription_started`
- `paywall_viewed`

### Revenue Metrics

Monitor in RevenueCat dashboard:
- Monthly Recurring Revenue (MRR)
- Average Revenue Per User (ARPU)
- Churn rate
- Conversion rate
- Lifetime Value (LTV)

## Cost Analysis

### API Costs

**fal.ai**: $0.03 per minute of video

**Pricing Strategy**:
- 1 credit = 1 minute of video
- Break-even: $0.03/credit
- Actual pricing: ~$0.167/credit (5.5x markup)
- Subscription discount: up to 40% off

**Example P&L**:
- Pro plan: $24.99/month for 180 credits
- API cost: $5.40
- Gross profit: $19.59 (78% margin)

## Troubleshooting

### Common Issues

**Firebase Authentication Fails**:
- Verify `GoogleService-Info.plist` is included
- Enable Anonymous authentication in Firebase Console
- Check bundle identifier matches Firebase project

**RevenueCat Products Not Loading**:
- Verify products exist in App Store Connect
- Products must be in "Ready to Submit" status
- Wait 15 minutes after creating products
- Check RevenueCat dashboard for product sync status

**fal.ai Upload Fails**:
- Verify API key is correct
- Check video file size (max 100MB)
- Ensure video has audio track
- Check network connectivity

**Credits Not Syncing**:
- Verify Firestore rules allow user access
- Check Firebase connection
- Review console logs for errors

### Debug Mode

Enable verbose logging:

```swift
// In AutoSubtitleApp.swift
init() {
    // Enable debug logging
    #if DEBUG
    Purchases.logLevel = .verbose
    FirebaseConfiguration.shared.setLoggerLevel(.debug)
    #endif
}
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Follow Swift style guide
4. Add tests for new features
5. Update documentation
6. Submit pull request

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Email**: support@autosubtitle.app
- **Documentation**: [docs.autosubtitle.app](https://docs.autosubtitle.app)
- **Issues**: [GitHub Issues](https://github.com/yourusername/autosubtitle/issues)

## Acknowledgments

- [fal.ai](https://fal.ai) for subtitle generation API
- [Firebase](https://firebase.google.com) for backend services
- [RevenueCat](https://revenuecat.com) for subscription management
- [Swift Community](https://swift.org) for excellent tooling

---

**Made with ❤️ using SwiftUI and AI**
# autosubtitle
