# Deployment Guide - AutoSubtitle

Complete guide for deploying AutoSubtitle to production.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Firebase Setup](#firebase-setup)
3. [RevenueCat Configuration](#revenuecat-configuration)
4. [App Store Connect Setup](#app-store-connect-setup)
5. [Build Configuration](#build-configuration)
6. [Testing in Production](#testing-in-production)
7. [App Store Submission](#app-store-submission)
8. [Post-Launch Monitoring](#post-launch-monitoring)

## Pre-Deployment Checklist

### Required Assets

- [ ] App icon (1024x1024 PNG)
- [ ] Launch screen
- [ ] Screenshots for all device sizes
  - [ ] 6.7" (iPhone 15 Pro Max)
  - [ ] 6.5" (iPhone 14 Plus)
  - [ ] 6.1" (iPhone 15 Pro)
  - [ ] 5.5" (iPhone 8 Plus)
- [ ] App preview videos (optional but recommended)
- [ ] Marketing materials

### Legal Documents

- [ ] Privacy Policy (https://yourapp.com/privacy)
- [ ] Terms of Service (https://yourapp.com/terms)
- [ ] EULA (optional, Apple's standard EULA is used by default)

### API Keys & Credentials

- [ ] Firebase project created
- [ ] RevenueCat account configured
- [ ] fal.ai API key obtained
- [ ] Apple Developer Program membership ($99/year)

## Firebase Setup

### 1. Create Firebase Project

```bash
# Visit Firebase Console
open https://console.firebase.google.com

# Create new project
# - Project name: AutoSubtitle Production
# - Enable Google Analytics (recommended)
# - Select or create Analytics account
```

### 2. Add iOS App

1. Click "Add app" → iOS
2. Bundle ID: `com.yourcompany.autosubtitle`
3. App nickname: `AutoSubtitle`
4. Download `GoogleService-Info.plist`
5. Add to Xcode project (drag into project navigator)

### 3. Enable Authentication

```bash
# In Firebase Console → Authentication
# 1. Click "Get Started"
# 2. Enable "Anonymous" provider
# 3. Save changes
```

### 4. Setup Firestore Database

```bash
# In Firebase Console → Firestore Database
# 1. Click "Create database"
# 2. Start in "Production mode"
# 3. Choose location (us-central, europe-west, etc.)
```

**Firestore Structure:**

```
/users/{userId}
  - firebaseUID: string
  - creditBalance: number
  - subscriptionTier: string
  - createdAt: timestamp
  - lastActive: timestamp
  - totalVideosProcessed: number
  - totalCreditsUsed: number
  - totalCreditsPurchased: number

  /transactions/{transactionId}
    - userId: string
    - amount: number
    - type: string
    - reference: string
    - timestamp: timestamp
    - balanceAfter: number
    - description: string

  /jobs/{jobId}
    - userId: string
    - status: string
    - videoFileName: string
    - videoDuration: number
    - creditsDeducted: number
    - creditsRefunded: number
    - falRequestId: string
    - resultVideoURL: string
    - transcription: string
    - createdAt: timestamp
    - completedAt: timestamp
```

### 5. Configure Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // User transactions
      match /transactions/{transactionId} {
        allow read: if request.auth != null && request.auth.uid == userId;
        allow create: if request.auth != null && request.auth.uid == userId;
        allow update, delete: if false; // Transactions are immutable
      }

      // User jobs
      match /jobs/{jobId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 6. Enable Analytics (Optional)

```bash
# In Firebase Console → Analytics
# 1. Events automatically tracked
# 2. Configure custom events if needed
# 3. Link to Google Analytics 4
```

## RevenueCat Configuration

### 1. Create RevenueCat Account

```bash
open https://app.revenuecat.com/signup
```

### 2. Create App

1. Click "Create new app"
2. Name: `AutoSubtitle`
3. Platform: iOS
4. Bundle ID: `com.yourcompany.autosubtitle`

### 3. Configure App Store Connect Integration

1. In RevenueCat Dashboard → App Settings
2. Click "Service Credentials"
3. Upload App Store Connect API Key:
   - Create key in App Store Connect
   - Download `.p8` file
   - Upload to RevenueCat

### 4. Create Products

**Subscriptions:**

```bash
# In RevenueCat Dashboard → Products
# Create offering: "Premium Plans"

Product ID: com.autosubtitle.subscription.starter.monthly
Name: Starter
Price: $9.99/month
Duration: 1 month

Product ID: com.autosubtitle.subscription.pro.monthly
Name: Pro
Price: $24.99/month
Duration: 1 month

Product ID: com.autosubtitle.subscription.ultimate.monthly
Name: Ultimate
Price: $49.99/month
Duration: 1 month
```

**One-Time Purchases:**

```bash
# Create offering: "Credit Packs"

Product ID: com.autosubtitle.credits.small
Name: Small Pack
Price: $4.99
Type: Consumable

Product ID: com.autosubtitle.credits.medium
Name: Medium Pack
Price: $14.99
Type: Consumable

Product ID: com.autosubtitle.credits.large
Name: Large Pack
Price: $39.99
Type: Consumable
```

### 5. Configure Entitlements

```bash
# In RevenueCat Dashboard → Entitlements

Entitlement ID: premium
Display Name: Premium Features
Products:
  - starter subscription
  - pro subscription
  - ultimate subscription
```

### 6. Set up Webhooks (Optional)

```bash
# Configure webhooks for events:
# - Customer subscribed
# - Customer renewed
# - Customer cancelled
# - Purchase failed

Webhook URL: https://your-backend.com/webhooks/revenuecat
Events: All
```

## App Store Connect Setup

### 1. Create App

```bash
# Visit App Store Connect
open https://appstoreconnect.apple.com

# 1. Click "My Apps" → "+"
# 2. Select "New App"
# 3. Platform: iOS
# 4. Name: AutoSubtitle
# 5. Primary Language: English (U.S.)
# 6. Bundle ID: com.yourcompany.autosubtitle
# 7. SKU: AUTOSUBTITLE001
# 8. User Access: Full Access
```

### 2. Configure In-App Purchases

**For each product:**

1. Click "Features" → "In-App Purchases"
2. Click "+" to create
3. Select type (Auto-Renewable Subscription or Consumable)
4. Reference Name: Matches RevenueCat
5. Product ID: Matches code
6. Price: Set pricing
7. Localization: Add descriptions
8. Review Information: Screenshot and review notes
9. Submit for review

**Subscription Groups:**

```bash
# Create subscription group
Group Name: Premium Plans
Reference Name: premium_plans

# Add subscriptions in ascending order
Level 1: Starter ($9.99)
Level 2: Pro ($24.99)
Level 3: Ultimate ($49.99)
```

### 3. App Information

```
Category: Photo & Video
Content Rights: Does not contain third-party content

Privacy Policy URL: https://autosubtitle.app/privacy
Terms of Use URL: https://autosubtitle.app/terms

Age Rating:
- Made for Kids: No
- Violence: None
- Medical/Treatment Information: None
- Gambling: No
- Unrestricted Web Access: No
- Rating: 4+
```

### 4. App Privacy

**Data Collection:**

```
User IDs
- Firebase Anonymous UID
- Purpose: App functionality
- Linked to user: Yes

Purchase History
- In-app purchases
- Purpose: App functionality
- Linked to user: Yes

Other Usage Data
- App interactions
- Purpose: Analytics
- Linked to user: No
```

## Build Configuration

### 1. Update Version & Build Number

```swift
// In Xcode Project Settings
Version: 1.0.0
Build: 1
```

### 2. Configure Signing

```bash
# In Xcode → Signing & Capabilities
Team: [Your Team]
Bundle Identifier: com.yourcompany.autosubtitle
Signing Certificate: Apple Distribution
Provisioning Profile: [Auto-generated]
```

### 3. Set Build Configuration

```swift
// Create Config.xcconfig for Production

// API Keys (use environment variables in CI/CD)
REVENUECAT_API_KEY = $(REVENUECAT_API_KEY_PROD)
FAL_API_KEY = $(FAL_API_KEY_PROD)

// Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = RELEASE
ENABLE_BITCODE = NO
SWIFT_OPTIMIZATION_LEVEL = -O
```

### 4. Configure Info.plist

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select videos for subtitle generation.</string>

<key>NSCameraUsageDescription</key>
<string>We need access to your camera to record videos for subtitle generation.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record videos with audio.</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>mailto</string>
</array>
```

### 5. Build Archive

```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Archive
xcodebuild archive \
  -workspace AutoSubtitle.xcworkspace \
  -scheme AutoSubtitle \
  -configuration Release \
  -archivePath ./build/AutoSubtitle.xcarchive \
  -allowProvisioningUpdates

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/AutoSubtitle.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
```

**ExportOptions.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

## Testing in Production

### 1. TestFlight

```bash
# Upload to App Store Connect
xcrun altool --upload-app \
  -t ios \
  -f ./build/AutoSubtitle.ipa \
  -u your-apple-id@email.com \
  -p @keychain:AC_PASSWORD

# Or use Transporter app
open -a Transporter
```

### 2. Internal Testing

1. Add internal testers in App Store Connect
2. Enable TestFlight
3. Distribute build to testers
4. Gather feedback

### 3. External Testing

1. Submit build for beta review (24-48 hours)
2. Add external testers (max 10,000)
3. Distribute via public link or invitations
4. Monitor crash reports and feedback

### 4. Sandbox Testing

Test in-app purchases with sandbox accounts:

```bash
# Create sandbox tester
App Store Connect → Users and Access → Sandbox Testers

# On device
Settings → App Store → Sandbox Account → [Your Test Account]

# Test flows:
- Purchase subscription
- Purchase credits
- Restore purchases
- Subscription renewal
- Subscription cancellation
```

## App Store Submission

### 1. Prepare Submission

```
App Information:
- Name: AutoSubtitle
- Subtitle: AI-Powered Video Subtitles
- Description: [See marketing copy]
- Keywords: video, subtitle, caption, ai, transcription
- Support URL: https://autosubtitle.app/support
- Marketing URL: https://autosubtitle.app

Pricing:
- Free app
- Contains in-app purchases

App Store Localization:
- English (U.S.) - Primary
- Spanish, French, German, Portuguese (optional)
```

### 2. Submit for Review

1. Select build from TestFlight
2. Add What's New (release notes)
3. Add rating and review information
4. Contact information
5. Demo account (if applicable)
6. Notes for review:
   - Explain credit system
   - Provide test account with credits
   - Mention fal.ai integration

### 3. Review Guidelines Compliance

Ensure compliance with:
- Human Interface Guidelines
- App Store Review Guidelines
- Subscription guidelines
- Data privacy requirements

### 4. Monitor Review Status

Typical timeline:
- Waiting for Review: 24-48 hours
- In Review: 24-48 hours
- Processing for App Store: 24 hours
- Ready for Sale: Immediately after approval

## Post-Launch Monitoring

### 1. Analytics Setup

```swift
// Track key events
Analytics.logEvent("video_processed", parameters: [
    "duration": videoDuration,
    "credits_used": creditsUsed,
    "language": language
])

Analytics.logEvent("purchase", parameters: [
    "product_id": productId,
    "price": price,
    "credits": credits
])
```

### 2. Monitor Metrics

**Firebase Console:**
- Daily Active Users (DAU)
- Retention rate
- Crash-free users
- Average session duration

**RevenueCat Dashboard:**
- Monthly Recurring Revenue (MRR)
- Active subscriptions
- Churn rate
- Conversion rate

**App Store Connect:**
- Downloads
- Crashes
- Reviews and ratings
- Conversion rate

### 3. Crash Reporting

```swift
// Enable Firebase Crashlytics
import FirebaseCrashlytics

// Log custom keys
Crashlytics.crashlytics().setCustomValue(userId, forKey: "user_id")
Crashlytics.crashlytics().setCustomValue(creditBalance, forKey: "credit_balance")

// Log non-fatal errors
Crashlytics.crashlytics().record(error: error)
```

### 4. Performance Monitoring

```bash
# Enable Firebase Performance
import FirebasePerformance

// Track custom traces
let trace = Performance.startTrace(name: "video_processing")
// ... process video
trace?.stop()
```

### 5. User Support

Set up support channels:
- In-app support button
- Email: support@autosubtitle.app
- FAQ/Help Center
- Social media channels

### 6. Version Updates

```bash
# For each update:
1. Increment build number
2. Update version for major changes
3. Write release notes
4. Test thoroughly
5. Submit for review
6. Monitor rollout
```

## Rollback Procedure

If critical issues are found:

1. **Stop rollout** in App Store Connect
2. **Fix the issue** in code
3. **Test fix** thoroughly
4. **Increment build number**
5. **Submit emergency update**
6. **Request expedited review** (if critical)

## Maintenance Schedule

**Weekly:**
- Review crash reports
- Monitor API costs
- Check user feedback

**Monthly:**
- Analyze revenue metrics
- Review user retention
- Update content/features

**Quarterly:**
- Performance optimization
- Feature updates
- Marketing campaigns

---

## Support & Resources

- **Apple Developer**: https://developer.apple.com
- **App Store Connect**: https://appstoreconnect.apple.com
- **Firebase Console**: https://console.firebase.google.com
- **RevenueCat Dashboard**: https://app.revenuecat.com
- **fal.ai Dashboard**: https://fal.ai/dashboard

**Questions?** Contact: devops@autosubtitle.app
