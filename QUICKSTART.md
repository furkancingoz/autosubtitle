# Quick Start Guide - AutoSubtitle

Get AutoSubtitle running in 15 minutes.

## Prerequisites

- macOS 13.0+ with Xcode 15.0+
- iOS 15.0+ device or simulator
- Apple Developer Account

## Step 1: Clone Repository (1 min)

```bash
git clone https://github.com/yourusername/autosubtitle.git
cd autosubtitle
```

## Step 2: Firebase Setup (5 min)

### Create Project
1. Visit [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Name: `AutoSubtitle`
4. Enable Analytics: Yes
5. Click "Create project"

### Add iOS App
1. Click iOS icon
2. Bundle ID: `com.yourcompany.autosubtitle`
3. Download `GoogleService-Info.plist`
4. Add to Xcode project:
   ```bash
   cp ~/Downloads/GoogleService-Info.plist ./AutoSubtitle/Resources/
   ```

### Enable Services
1. **Authentication**:
   - Go to Authentication → Sign-in method
   - Enable "Anonymous"
   - Save

2. **Firestore**:
   - Go to Firestore Database
   - Click "Create database"
   - Production mode → us-central1
   - Enable

3. **Security Rules**:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth.uid == userId;
         match /{document=**} {
           allow read, write: if request.auth.uid == userId;
         }
       }
     }
   }
   ```

## Step 3: RevenueCat Setup (5 min)

### Create Account
1. Visit [RevenueCat](https://app.revenuecat.com/signup)
2. Sign up and verify email

### Create Project & App
1. Click "Create new project"
2. Name: `AutoSubtitle`
3. Click "Add app" → iOS
4. Bundle ID: `com.yourcompany.autosubtitle`

### Get API Key
1. Project Settings → API Keys
2. Copy the **Public iOS SDK key** (starts with `appl_`)

## Step 4: fal.ai Setup (2 min)

### Create Account
1. Visit [fal.ai](https://fal.ai)
2. Sign up and verify email

### Get API Key
1. Dashboard → API Keys
2. Click "Create new key"
3. Name: `AutoSubtitle`
4. Copy the key (starts with `fal_`)

## Step 5: Configure App (2 min)

Edit `AutoSubtitle/App/AutoSubtitleApp.swift`:

```swift
init() {
    // Configure Firebase
    FirebaseApp.configure()

    // Configure RevenueCat - Replace with your key
    let revenueCatAPIKey = "appl_YOUR_REVENUECAT_KEY"
    RevenueCatManager.shared.configure(apiKey: revenueCatAPIKey)

    // Configure FalAI - Replace with your key
    let falAPIKey = "YOUR_FAL_API_KEY"
    FalAIService.shared.setAPIKey(falAPIKey)
}
```

## Step 6: Run the App (1 min)

### Open in Xcode
```bash
open AutoSubtitle.xcodeproj
```

### Select Target
1. Select your development team in Signing & Capabilities
2. Choose iOS Simulator (iPhone 15 Pro)
3. Press `Cmd + R` to run

### First Launch
1. App will show onboarding
2. Click "Get Started"
3. Anonymous authentication happens automatically
4. You get 5 free credits!

## Quick Test

### Test Video Processing

1. **Select Video**:
   - Tap "Select a Video" on Home screen
   - Choose a short video (< 1 min recommended for testing)

2. **Customize** (optional):
   - Change language
   - Adjust position (top/center/bottom)
   - Modify font size

3. **Process**:
   - Tap "Generate Subtitles"
   - Watch status updates
   - Wait for completion (usually 30-60 seconds)

4. **View Result**:
   - Tap "View Result"
   - See your subtitled video!

### Test Credits

1. **Check Balance**:
   - Home screen shows credit balance
   - Tap "Add Credits" to see paywall

2. **View History**:
   - Go to History tab
   - See processed videos
   - View transaction history in Credits tab

## Development Tips

### Using Sandbox for IAP Testing

1. **Create Sandbox Account**:
   - App Store Connect → Users and Access → Sandbox Testers
   - Create test account

2. **Use on Device**:
   - Settings → App Store → Sandbox Account
   - Sign in with test account

3. **Test Purchases**:
   - All purchases are free in sandbox
   - Test all flows without real charges

### Debug Logging

Enable verbose logging for debugging:

```swift
// In AutoSubtitleApp.swift init()
#if DEBUG
Purchases.logLevel = .verbose
print("🐛 Debug mode enabled")
#endif
```

### Reset App State

```bash
# Reset simulator
xcrun simctl erase all

# Or manually reset
Settings → General → Transfer or Reset → Erase All Content and Settings
```

## Common Issues

### "Firebase not configured"
**Solution**: Ensure `GoogleService-Info.plist` is in project and added to target

### "Products not loading"
**Solution**:
- RevenueCat needs products from App Store Connect
- For testing, products will be empty initially
- Configure products in App Store Connect first

### "Video upload fails"
**Solution**:
- Check fal.ai API key is correct
- Verify video is < 100MB
- Ensure video has audio track

### "Credits not updating"
**Solution**:
- Pull to refresh in Credits tab
- Check Firestore security rules
- Verify Firebase connection in console logs

## Next Steps

Now that you have the app running:

1. **Configure Products** → See [DEPLOYMENT.md](./DEPLOYMENT.md)
2. **Customize UI** → Edit views in `AutoSubtitle/Views/`
3. **Add Features** → See [ARCHITECTURE.md](./ARCHITECTURE.md)
4. **Deploy to TestFlight** → Follow [DEPLOYMENT.md](./DEPLOYMENT.md)

## Resources

- **Full Documentation**: [README.md](./README.md)
- **Architecture**: [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Configuration**: [CONFIGURATION.md](./CONFIGURATION.md)
- **Deployment**: [DEPLOYMENT.md](./DEPLOYMENT.md)

## Support

Need help?
- **Email**: support@autosubtitle.app
- **Issues**: [GitHub Issues](https://github.com/yourusername/autosubtitle/issues)

---

**You're all set! Happy coding! 🚀**
