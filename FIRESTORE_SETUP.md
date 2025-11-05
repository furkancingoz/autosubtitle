# Firestore Hızlı Kurulum

## ⚡ Hızlı Çözüm (2 dakika)

### 1. Firestore API'sini Etkinleştirin

**Otomatik Link:**
```
https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=autosub-753e6
```

Veya manuel:

1. [Google Cloud Console](https://console.cloud.google.com) açın
2. Proje: `autosub-753e6` seçin
3. Arama çubuğuna "Firestore" yazın
4. **Cloud Firestore API** seçin
5. **"Enable"** butonuna tıklayın
6. 1-2 dakika bekleyin

### 2. Firestore Database Oluşturun

1. [Firebase Console](https://console.firebase.google.com) açın
2. Proje: `autosub-753e6` seçin
3. Sol menüden **Build** → **Firestore Database**
4. **"Create database"** butonuna tıklayın
5. **"Start in production mode"** seçin
6. Location: **us-central1** (veya yakın bölge)
7. **"Enable"** butonuna tıklayın

### 3. Güvenlik Kuralları

Firestore → **Rules** sekmesinde bu kuralları ekleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcı dokümanları
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Alt koleksiyonlar (transactions, jobs)
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

**"Publish"** butonuna tıklayın.

## 🎯 Test Edin

Uygulamayı tekrar çalıştırın:

```bash
# Xcode'da Cmd+R
```

Görmek istediğiniz log'lar:

```
✅ Firebase configured
🚀 Starting app initialization...
📡 Fetching Remote Config...
✅ Remote Config activated successfully
⚠️ RevenueCat API key is missing (development mode)  ← OK
⚠️ fal.ai API key is missing (development mode)      ← OK
✅ Configuration validated successfully               ← ✅
🔐 Attempting auto sign-in...
✅ Anonymous sign-in successful: [user_id]
👤 Loading user data...
✅ New user created: [user_id]
✅ Credits loaded from Keychain: 100                  ← ✅
✅ App initialization complete!                       ← ✅
```

## 🔑 API Key'leri Eklemek (Opsiyonel)

İsterseniz şimdi Remote Config'e de API key'leri ekleyebilirsiniz:

### Firebase Console → Remote Config

**1. RevenueCat API Key:**
```
Parameter key: revenuecat_api_key
Default value: [RevenueCat Dashboard'dan alın]
```

**2. fal.ai API Key:**
```
Parameter key: fal_api_key
Default value: [fal.ai Dashboard'dan alın]
```

**"Publish changes"** butonuna tıklayın.

## ✅ Kontrol Listesi

- [ ] Firestore API etkinleştirildi
- [ ] Firestore Database oluşturuldu
- [ ] Güvenlik kuralları yayınlandı
- [ ] Uygulama başarıyla açıldı
- [ ] 100 kredi görünüyor

## 🎬 Video İşleme için

Video işleme özelliğini test etmek istiyorsanız:

1. **fal.ai API key** gerekli
2. [fal.ai](https://fal.ai) → Sign up
3. Dashboard → API Keys → Create new key
4. Firebase Remote Config'e ekleyin: `fal_api_key`

## 💰 Satın Alma için

Satın alma özelliğini test etmek istiyorsanız:

1. **RevenueCat API key** gerekli
2. [RevenueCat](https://app.revenuecat.com) → Sign up
3. Project → API Keys → Public iOS SDK key
4. Firebase Remote Config'e ekleyin: `revenuecat_api_key`

---

**Şimdi uygulama çalışmalı! 🎉**
