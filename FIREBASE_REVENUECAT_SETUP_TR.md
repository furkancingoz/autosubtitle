# Firebase & RevenueCat Kurulum Rehberi (Türkçe)

Bu dokümanda Firebase ve RevenueCat SDK'larını projeye nasıl entegre edeceğinizi ve Remote Config ile API key'leri nasıl yöneteceğinizi bulacaksınız.

## İçindekiler

1. [Firebase SDK Kurulumu](#firebase-sdk-kurulumu)
2. [RevenueCat SDK Kurulumu](#revenuecat-sdk-kurulumu)
3. [Firebase Remote Config Kurulumu](#firebase-remote-config-kurulumu)
4. [API Key'leri Ekleme](#api-keyleri-ekleme)
5. [Test ve Doğrulama](#test-ve-doğrulama)

## Firebase SDK Kurulumu

### 1. Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com) adresine gidin
2. **"Add project"** butonuna tıklayın
3. Proje adı: `AutoSubtitle` (veya tercih ettiğiniz isim)
4. Google Analytics: **Etkinleştirin** (önerilir)
5. **"Create project"** butonuna tıklayın

### 2. iOS Uygulaması Ekleme

1. Firebase Console'da projenize tıklayın
2. iOS simgesine tıklayın (veya + butonuna tıklayıp iOS seçin)
3. Bundle ID'yi girin: `com.yourcompany.autosubtitle`
   - Xcode'da: Project → Targets → AutoSubtitle → General → Bundle Identifier
4. App nickname (opsiyonel): `AutoSubtitle Production`
5. **"Register app"** butonuna tıklayın
6. **`GoogleService-Info.plist`** dosyasını indirin

### 3. GoogleService-Info.plist Dosyasını Projeye Ekleme

```bash
# Terminalde:
cd /Users/furkancingoz/Desktop/new\ project\ folder/autosubtitle
cp ~/Downloads/GoogleService-Info.plist ./AutoSubtitle/Resources/

# Veya Xcode'da:
# GoogleService-Info.plist dosyasını Xcode'a sürükle-bırak yap
# "Copy items if needed" seçeneğini işaretle
# Target: AutoSubtitle seçili olsun
```

### 4. Firebase SDK Paketlerini Ekleme

#### Swift Package Manager Kullanarak:

1. Xcode'da projenizi açın
2. **File** → **Add Package Dependencies...**
3. URL'yi girin: `https://github.com/firebase/firebase-ios-sdk.git`
4. **Version:** "Up to Next Major Version" → `10.20.0`
5. **Add Package** butonuna tıklayın

#### Şu paketleri seçin:
- ✅ **FirebaseAuth** - Kimlik doğrulama
- ✅ **FirebaseFirestore** - Veritabanı
- ✅ **FirebaseAnalytics** - Analizler
- ✅ **FirebaseRemoteConfig** - Uzaktan yapılandırma

6. **Add Package** butonuna tıklayın

### 5. Firebase'i Kod İçinde Yapılandırma

`AutoSubtitleApp.swift` dosyası zaten yapılandırılmış durumda:

```swift
import Firebase

@main
struct AutoSubtitleApp: App {
    init() {
        // Firebase otomatik olarak yapılandırılıyor
        FirebaseApp.configure()
        print("✅ Firebase configured")
    }
}
```

### 6. Firebase Servislerini Etkinleştirme

#### Authentication (Kimlik Doğrulama)

1. Firebase Console → **Authentication**
2. **"Get started"** butonuna tıklayın
3. **"Sign-in method"** sekmesine gidin
4. **"Anonymous"** sağlayıcısını etkinleştirin
5. **"Save"** butonuna tıklayın

#### Firestore Database (Veritabanı)

1. Firebase Console → **Firestore Database**
2. **"Create database"** butonuna tıklayın
3. **"Start in production mode"** seçin
4. Location: **us-central1** (veya size yakın bir bölge)
5. **"Enable"** butonuna tıklayın

#### Firestore Güvenlik Kuralları

Rules sekmesinde bu kuralları ekleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcı dokümanları
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Alt koleksiyonlar
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

**"Publish"** butonuna tıklayın.

## RevenueCat SDK Kurulumu

### 1. RevenueCat Hesabı Oluşturma

1. [RevenueCat](https://app.revenuecat.com/signup) adresine gidin
2. Ücretsiz hesap oluşturun
3. Email adresinizi doğrulayın

### 2. Proje ve Uygulama Oluşturma

1. Dashboard'da **"Create new project"** butonuna tıklayın
2. Project name: `AutoSubtitle`
3. **"Create"** butonuna tıklayın
4. **"Add app"** butonuna tıklayın
5. Platform: **iOS**
6. App name: `AutoSubtitle`
7. Bundle ID: `com.yourcompany.autosubtitle` (Firebase'dekiyle aynı olmalı)
8. **"Save"** butonuna tıklayın

### 3. App Store Connect Entegrasyonu

#### Seçenek A: App Store Connect API Key (Önerilen)

1. [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access**
2. **Keys** sekmesi → **App Store Connect API** → **"+"** butonu
3. Key Name: `RevenueCat Integration`
4. Access: **Admin** veya **App Manager**
5. **"Generate"** butonu → `.p8` dosyasını indirin
6. **Key ID** ve **Issuer ID**'yi not alın

RevenueCat'te:
1. App Settings → **Service Credentials**
2. `.p8` dosyasını yükleyin
3. Key ID ve Issuer ID'yi girin
4. **"Save"** butonuna tıklayın

### 4. RevenueCat SDK Paketini Ekleme

1. Xcode'da projenizi açın
2. **File** → **Add Package Dependencies...**
3. URL'yi girin: `https://github.com/RevenueCat/purchases-ios.git`
4. **Version:** "Up to Next Major Version" → `4.37.0`
5. **Add Package** butonuna tıklayın
6. **RevenueCat** paketini seçin
7. **Add Package** butonuna tıklayın

### 5. RevenueCat API Key'i Alma

1. RevenueCat Dashboard → Project Settings → **API Keys**
2. **Public Apple SDK key**'i kopyalayın (örnek: `appl_xxxxxxxxx`)
3. Bu key'i Firebase Remote Config'e ekleyeceksiniz

## Firebase Remote Config Kurulumu

### 1. Remote Config'i Etkinleştirme

1. Firebase Console → **Engage** → **Remote Config**
2. İlk kez kullanıyorsanız **"Get started"** butonuna tıklayın

### 2. Parametreleri Ekleme

#### RevenueCat API Key

1. **"Add parameter"** butonuna tıklayın
2. Formu doldurun:
   - **Parameter key:** `revenuecat_api_key`
   - **Default value:** `appl_xxxxxxxxx` (RevenueCat'ten aldığınız key)
   - **Description:** RevenueCat iOS SDK API Key
   - **Value type:** String
3. **"Save"** butonuna tıklayın

#### fal.ai API Key

1. **"Add parameter"** butonuna tıklayın
2. Formu doldurun:
   - **Parameter key:** `fal_api_key`
   - **Default value:** `fal_xxxxxxxxx` (fal.ai'dan aldığınız key)
   - **Description:** fal.ai API Key for subtitle generation
   - **Value type:** String
3. **"Save"** butonuna tıklayın

### 3. Diğer Parametreler (Opsiyonel)

Bu parametreleri de ekleyebilirsiniz:

```
enable_subscriptions = true (Boolean)
enable_one_time_purchases = true (Boolean)
max_video_size_mb = 100 (Number)
max_video_duration_minutes = 60 (Number)
free_user_credits = 5 (Number)
max_retries = 3 (Number)
```

### 4. Değişiklikleri Yayınlama

**ÖNEMLİ:** Sağ üstteki **"Publish changes"** butonuna tıklayın!

Değişiklikleri yayınlamazsanız, uygulama yeni değerleri almaz.

## API Key'leri Ekleme

### RevenueCat API Key Nereden Alınır?

1. [RevenueCat Dashboard](https://app.revenuecat.com)
2. Projenize tıklayın
3. ⚙️ → **API Keys**
4. **Public Apple SDK key**'i kopyalayın
5. Format: `appl_xxxxxxxxxxxxxxxxx`

### fal.ai API Key Nereden Alınır?

1. [fal.ai](https://fal.ai) hesabınıza giriş yapın
2. Dashboard → **API Keys**
3. **"Create new key"** butonuna tıklayın
4. Name: `AutoSubtitle Production`
5. API key'i kopyalayın
6. Format: `fal_xxxxxxxxxxxxxxxxx`

### Toplu Parametre Ekleme (JSON Import)

Tüm parametreleri tek seferde eklemek için `REMOTE_CONFIG_SETUP.md` dosyasındaki JSON template'i kullanabilirsiniz.

## Test ve Doğrulama

### 1. Xcode'da Çalıştırma

```bash
# Terminalde
cd /Users/furkancingoz/Desktop/new\ project\ folder/autosubtitle
open AutoSubtitle.xcodeproj

# Xcode'da Cmd+R ile çalıştırın
```

### 2. Log'ları Kontrol Etme

Xcode Console'da şu log'ları göreceksiniz:

```
✅ Firebase configured
🚀 Starting app initialization...
📡 Fetching Remote Config...
📋 Remote Config values:
  RevenueCat API Key: SET (appl_xxxxx...)
  fal.ai API Key: SET (fal_xxxxx...)
  Enable Subscriptions: true
  Max Video Size: 100 MB
  Free User Credits: 5
✅ Configuration validated successfully
💰 Configuring RevenueCat...
✅ RevenueCat configured
🎬 Configuring fal.ai service...
🔐 Attempting auto sign-in...
✅ Anonymous sign-in successful: [user_id]
👤 Loading user data...
✅ New user created: [user_id]
✅ Credits loaded from Keychain: 5
✅ App initialization complete!
```

### 3. Hata Durumları

Eğer bir şeyler yanlış gittiyse:

```
❌ RevenueCat API key is missing
❌ fal.ai API key is missing
❌ Configuration validation failed
⚠️ RevenueCat API key not available, skipping configuration
```

**Çözüm:**
1. Firebase Console → Remote Config → Parametreleri kontrol edin
2. **"Publish changes"** butonuna tıkladığınızdan emin olun
3. Uygulamayı kapatıp tekrar açın
4. Simulator'ü sıfırlayın: Device → Erase All Content and Settings

### 4. Manuel Test

Uygulamada test etmek için:

1. **Onboarding'i Tamamlayın:** "Get Started" butonuna tıklayın
2. **Kredi Kontrolü:** Home ekranında 5 kredi görmeli
3. **Paywall Testi:** "Add Credits" butonuna tıklayın
4. **Video Yükleme:** Bir video seçin ve işleme alın

## Sık Karşılaşılan Sorunlar

### Firebase Configure Hatası

**Hata:**
```
Firebase not configured
GoogleService-Info.plist file not found
```

**Çözüm:**
1. `GoogleService-Info.plist` dosyasının projenizde olduğunu kontrol edin
2. Xcode'da dosyaya sağ tıklayın → "Show in Finder"
3. Target Membership'in işaretli olduğunu kontrol edin

### RevenueCat Products Yüklenmiyor

**Sebep:** App Store Connect'te ürünler henüz oluşturulmamış

**Çözüm:**
- Development aşamasında normal, App Store Connect'te ürünleri oluşturun
- [DEPLOYMENT.md](./DEPLOYMENT.md) dosyasına bakın

### Remote Config Fetch Timeout

**Sebep:** İnternet bağlantısı yok veya Firebase'e erişilemiyor

**Çözüm:**
1. İnternet bağlantınızı kontrol edin
2. Firebase Console'da proje durumunu kontrol edin
3. VPN kullanıyorsanız kapatmayı deneyin

## Güvenlik Kontrol Listesi

- ✅ API key'leri Remote Config'de saklandı
- ✅ API key'leri kod içine yazılmadı
- ✅ `.gitignore` dosyası `GoogleService-Info.plist`'i içeriyor
- ✅ Production ve Development için ayrı Firebase projeleri var
- ✅ Firestore güvenlik kuralları yapılandırıldı
- ✅ Anonymous authentication etkinleştirildi

## Sonraki Adımlar

1. ✅ Firebase ve RevenueCat SDK'ları kuruldu
2. ✅ Remote Config yapılandırıldı
3. ✅ API key'leri eklendi
4. ✅ Uygulama test edildi
5. 📱 **Sonraki:** [QUICKSTART.md](./QUICKSTART.md) - İlk video işleme

## Yardım ve Kaynaklar

### Resmi Dokümantasyon

- **Firebase iOS SDK:** https://firebase.google.com/docs/ios/setup
- **Firebase Remote Config:** https://firebase.google.com/docs/remote-config
- **RevenueCat iOS SDK:** https://docs.revenuecat.com/docs/ios
- **fal.ai API:** https://fal.ai/docs

### Destek

- **Email:** support@autosubtitle.app
- **GitHub Issues:** [Repository link]

## Özet Kontrol Listesi

Kurulum tamamlandı mı? Kontrol edin:

- [ ] Firebase projesi oluşturuldu
- [ ] iOS uygulaması Firebase'e eklendi
- [ ] `GoogleService-Info.plist` projeye eklendi
- [ ] Firebase SDK paketleri yüklendi
- [ ] Authentication etkinleştirildi (Anonymous)
- [ ] Firestore Database oluşturuldu
- [ ] Firestore güvenlik kuralları ayarlandı
- [ ] RevenueCat hesabı oluşturuldu
- [ ] RevenueCat projesi ve uygulaması oluşturuldu
- [ ] RevenueCat SDK paketi yüklendi
- [ ] Remote Config etkinleştirildi
- [ ] `revenuecat_api_key` parametresi eklendi
- [ ] `fal_api_key` parametresi eklendi
- [ ] Remote Config değişiklikleri yayınlandı
- [ ] Uygulama çalıştırıldı ve test edildi
- [ ] Log'larda "✅ Configuration validated successfully" görüldü

Tüm adımlar tamamlandıysa, **tebrikler!** 🎉 Uygulamanız kullanıma hazır!

---

**Oluşturulma:** Ocak 2025
**Güncelleme:** Remote Config entegrasyonu eklendi
