# AutoSubtitle MVP - System Architecture

## Overview
A mobile application that automatically generates subtitles for videos using fal.ai API with a credit-based monetization system.

## Technology Stack

### Frontend
- **Platform**: iOS (Swift/SwiftUI)
- **Minimum Version**: iOS 15.0+
- **UI Framework**: SwiftUI with MVVM architecture

### Backend Services
- **Authentication**: Firebase Auth (Anonymous)
- **Monetization**: RevenueCat for In-App Purchases
- **API Service**: fal.ai auto-subtitle API
- **Storage**:
  - UserDefaults for user preferences
  - Keychain for secure credential storage
  - Firebase Firestore for user data sync

### Third-Party SDKs
- Firebase SDK (Auth, Firestore, Analytics)
- RevenueCat SDK
- Alamofire for networking

## System Components

### 1. Authentication Layer
```
FirebaseAuthManager
├── Anonymous Sign-In
├── Account Persistence
├── User ID Management
└── Token Refresh
```

**Features:**
- Automatic anonymous authentication on first launch
- Persistent user sessions across app launches
- Automatic account upgrade support (future)

### 2. Credit Management System
```
CreditManager
├── Credit Balance Storage (Keychain)
├── Credit Deduction
├── Credit Addition
├── Transaction History
├── Refund Processing
└── Credit Synchronization (Firebase)
```

**Credit Rules:**
- 1 credit = 1 minute of video processing
- Minimum deduction: 1 credit
- Fractional videos round up (e.g., 1.5 min = 2 credits)
- Failed processing = automatic refund
- Credits stored securely in Keychain
- Synced to Firebase for cross-device support

### 3. Monetization System (RevenueCat)

**Subscription Tiers:**

| Tier | Price | Credits/Month | Features |
|------|-------|---------------|----------|
| Free | $0 | 5 credits | • 5 videos/month<br>• Standard quality<br>• Watermark |
| Starter | $9.99/month | 60 credits | • 60 videos/month<br>• HD quality<br>• No watermark<br>• 3 font styles |
| Pro | $24.99/month | 180 credits | • 180 videos/month<br>• HD quality<br>• No watermark<br>• All fonts<br>• Priority processing<br>• Batch processing |
| Ultimate | $49.99/month | 500 credits | • 500 videos/month<br>• 4K quality<br>• No watermark<br>• All features<br>• API access<br>• Custom branding |

**One-Time Purchases:**

| Package | Price | Credits |
|---------|-------|---------|
| Small | $4.99 | 20 credits |
| Medium | $14.99 | 75 credits |
| Large | $39.99 | 250 credits |

### 4. fal.ai Integration

**Service Architecture:**
```
FalAIService
├── Request Submission
├── Queue Status Polling
├── Result Retrieval
├── Error Handling
└── Retry Logic
```

**Processing Flow:**
1. **Upload Phase**: Video uploaded to fal.ai (pre-signed URL)
2. **Queue Phase**: Request submitted, returns request_id
3. **Processing Phase**: Poll status every 3s (IN_QUEUE → IN_PROGRESS)
4. **Completion Phase**: Download result or handle error
5. **Cleanup Phase**: Update credits, save history

**Error Handling:**
- Network errors → Retry up to 3 times
- API errors → Refund credits
- Timeout (>10 min) → Refund + notification
- Invalid file → Reject before credit deduction

### 5. Video Processing Pipeline

```
VideoProcessor
├── Video Validation (format, size, duration)
├── Credit Check
├── Credit Pre-Deduction
├── Upload to fal.ai
├── Status Monitoring
├── Result Download
├── Credit Finalization/Refund
└── History Update
```

**States:**
- `idle`: Ready for new job
- `validating`: Checking video
- `uploading`: Sending to fal.ai
- `queued`: In fal.ai queue
- `processing`: Being processed
- `downloading`: Retrieving result
- `completed`: Success
- `failed`: Error occurred
- `cancelled`: User cancelled
- `refunded`: Credits returned

### 6. Data Models

**User Model:**
```swift
struct User {
    let id: String // Firebase UID
    var creditBalance: Int
    var subscriptionTier: SubscriptionTier
    var createdAt: Date
    var lastActive: Date
    var totalVideosProcessed: Int
}
```

**Transaction Model:**
```swift
struct CreditTransaction {
    let id: String
    let userId: String
    let amount: Int // positive = added, negative = deducted
    let type: TransactionType // purchase, deduction, refund, bonus
    let reference: String? // video job ID or purchase ID
    let timestamp: Date
    let balance: Int // balance after transaction
}
```

**Video Job Model:**
```swift
struct VideoJob {
    let id: String
    let userId: String
    let status: JobStatus
    let videoUrl: URL
    let videoDuration: TimeInterval
    let creditsDeducted: Int
    let falRequestId: String?
    let resultUrl: URL?
    let transcription: String?
    let subtitleCount: Int?
    let createdAt: Date
    let completedAt: Date?
    let errorMessage: String?
    let retryCount: Int
}
```

### 7. UI Architecture

**Screen Flow:**
```
SplashScreen
    ↓
OnboardingFlow (first launch only)
    ↓
MainTabView
├── HomeTab (Video Upload)
├── HistoryTab (Past Jobs)
├── CreditsTab (Balance & Purchase)
└── SettingsTab (Account & Preferences)
```

**Paywall Triggers:**
- Out of credits
- Accessing premium features
- After 3 free videos
- Manual navigation from Credits tab

## Security Measures

### Keychain Storage
- Credit balance encrypted in Keychain
- fal.ai API key stored securely
- RevenueCat user ID protected

### API Security
- All requests over HTTPS
- API keys never hardcoded
- Request signature validation
- Rate limiting protection

### Data Validation
- Video file validation before upload
- Credit balance verification before processing
- Duplicate request prevention
- Timestamp validation for transactions

## Analytics & Monitoring

**Key Metrics:**
- Daily Active Users (DAU)
- Credit consumption rate
- Conversion rate (free → paid)
- Average revenue per user (ARPU)
- Processing success rate
- Average processing time
- Error rate by type

**Events to Track:**
- App launch
- Video upload started
- Processing completed/failed
- Credit purchase
- Subscription started/cancelled
- Paywall displayed/dismissed

## Error Recovery Strategies

| Error Type | Recovery Strategy |
|------------|-------------------|
| Network timeout | Retry 3x with exponential backoff |
| API rate limit | Queue locally, retry after delay |
| Invalid video | Show error, no credit deduction |
| Processing failure | Auto-refund credits |
| Payment failure | Retry transaction |
| Auth token expired | Silent re-authentication |
| Out of credits | Show paywall |
| App crash during processing | Resume on restart |

## Performance Optimization

- Video upload: Compress before sending (if >50MB)
- UI: Async operations with progress indicators
- Caching: Cache recent job results for 24h
- Polling: Exponential backoff (3s → 5s → 10s)
- Background processing: Support background uploads

## Future Enhancements (Post-MVP)

1. Social authentication (Google, Apple)
2. Video editing features (trim, crop)
3. Subtitle editing interface
4. Multiple language support
5. Batch processing
6. Cloud storage integration (Drive, Dropbox)
7. Referral program
8. Team/organization accounts
9. Custom subtitle styling templates
10. Export formats (SRT, VTT, ASS)

## Development Phases

### Phase 1: Core Foundation (Week 1-2)
- Project setup
- Firebase Auth integration
- Basic UI shell
- fal.ai service integration

### Phase 2: Credit System (Week 2-3)
- Credit manager implementation
- Keychain storage
- Transaction history
- Firebase sync

### Phase 3: Monetization (Week 3-4)
- RevenueCat integration
- Paywall UI
- Purchase flows
- Subscription management

### Phase 4: Video Processing (Week 4-5)
- Video picker
- Upload flow
- Status monitoring
- Result display

### Phase 5: Polish & Testing (Week 5-6)
- Error handling refinement
- UI/UX improvements
- Testing & bug fixes
- App Store preparation

## API Cost Management

**Cost Structure:**
- fal.ai: $0.03/minute
- Our pricing: 1 credit/minute
- Break-even: $0.03/credit
- Minimum credit price: ~$0.20/credit (400% markup)
- Subscription value: Discounted bulk credits

**Example P&L:**
- Starter ($9.99): 60 credits → $1.80 API cost → $8.19 profit (82% margin)
- Pro ($24.99): 180 credits → $5.40 API cost → $19.59 profit (78% margin)

## Compliance & Legal

- App Store Guidelines compliance
- GDPR compliance (EU users)
- COPPA compliance (age restriction)
- Terms of Service
- Privacy Policy
- Refund policy (Apple's standard)
- Content policy (prohibited content)
