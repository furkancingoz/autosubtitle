# Firebase Remote Config Setup Guide

Bu dokümanda Firebase Remote Config'i nasıl kuracağınızı ve API key'lerinizi güvenli bir şekilde nasıl yöneteceğinizi bulacaksınız.

## İçindekiler

1. [Remote Config Nedir?](#remote-config-nedir)
2. [Kurulum Adımları](#kurulum-adımları)
3. [API Key'leri Ekleme](#api-keyleri-ekleme)
4. [Parametre Listesi](#parametre-listesi)
5. [Test ve Doğrulama](#test-ve-doğrulama)

## Remote Config Nedir?

Firebase Remote Config, uygulamanızın davranışını ve görünümünü uygulama güncellemesi yayınlamadan değiştirmenize olanak tanır. Bu projede:

- **API Key'leri** güvenli bir şekilde yönetmek için
- **Feature flag'leri** açıp kapatmak için
- **Limitleri** dinamik olarak ayarlamak için
- **Fiyatlandırmayı** anında değiştirmek için

kullanıyoruz.

## Kurulum Adımları

### Adım 1: Firebase Console'a Giriş

1. [Firebase Console](https://console.firebase.google.com) adresine gidin
2. Projenizi seçin (AutoSubtitle)
3. Sol menüden **Engage** → **Remote Config** seçin

### Adım 2: Remote Config'i Etkinleştirin

1. İlk kez kullanıyorsanız **"Get Started"** butonuna tıklayın
2. Remote Config açıldığında **"Add parameter"** butonunu göreceksiniz

### Adım 3: Firebase SDK'yı Projeye Ekleyin

Xcode projenizde **Package Dependencies** ekleyin:

```swift
// Package.swift veya Xcode → File → Add Package Dependency
https://github.com/firebase/firebase-ios-sdk.git

// Şu paketleri seçin:
- FirebaseAuth
- FirebaseFirestore
- FirebaseAnalytics
- FirebaseRemoteConfig ✅ (YENİ)
```

## API Key'leri Ekleme

### RevenueCat API Key

1. Firebase Console → Remote Config
2. **"Add parameter"** butonuna tıklayın
3. Parametreyi doldurun:

```
Parameter key: revenuecat_api_key
Default value: [RevenueCat Dashboard'dan aldığınız API key]
Description: RevenueCat iOS SDK API Key
Value type: String
```

4. **"Save"** butonuna tıklayın

### fal.ai API Key

1. **"Add parameter"** butonuna tekrar tıklayın
2. Parametreyi doldurun:

```
Parameter key: fal_api_key
Default value: [fal.ai Dashboard'dan aldığınız API key]
Description: fal.ai API Key for subtitle generation
Value type: String
```

3. **"Save"** butonuna tıklayın

### Değişiklikleri Yayınlayın

**ÖNEMLİ:** Parametreleri ekledikten sonra mutlaka **"Publish changes"** butonuna tıklayın!

## Parametre Listesi

Tüm parametrelerin tam listesi ve açıklamaları:

### API Keys (Zorunlu)

| Parameter Key | Type | Description | Örnek Değer |
|--------------|------|-------------|-------------|
| `revenuecat_api_key` | String | RevenueCat iOS SDK API Key | `appl_xxxxxxxxx` |
| `fal_api_key` | String | fal.ai API Key | `fal_xxxxxxxxx` |

### Feature Flags (Opsiyonel)

| Parameter Key | Type | Default | Description |
|--------------|------|---------|-------------|
| `enable_subscriptions` | Boolean | `true` | Abonelikleri etkinleştir |
| `enable_one_time_purchases` | Boolean | `true` | Tek seferlik satın almaları etkinleştir |
| `enable_video_editing` | Boolean | `false` | Video düzenleme özelliğini etkinleştir (gelecek) |
| `enable_batch_processing` | Boolean | `false` | Toplu işleme özelliğini etkinleştir (gelecek) |

### Limits (Opsiyonel)

| Parameter Key | Type | Default | Description |
|--------------|------|---------|-------------|
| `max_video_size_mb` | Number | `100` | Maksimum video boyutu (MB) |
| `max_video_duration_minutes` | Number | `60` | Maksimum video süresi (dakika) |
| `free_user_credits` | Number | `5` | Ücretsiz kullanıcılara verilen başlangıç kredisi |
| `max_retries` | Number | `3` | Başarısız işlemler için maksimum deneme sayısı |

### Pricing (Opsiyonel)

| Parameter Key | Type | Default | Description |
|--------------|------|---------|-------------|
| `starter_monthly_credits` | Number | `60` | Starter planı aylık kredi |
| `pro_monthly_credits` | Number | `180` | Pro planı aylık kredi |
| `ultimate_monthly_credits` | Number | `500` | Ultimate planı aylık kredi |

## Toplu Ekleme (JSON Import)

Tüm parametreleri tek seferde eklemek için:

1. Firebase Console → Remote Config
2. Sağ üstteki **"⋮"** (3 nokta) menüsüne tıklayın
3. **"Download template"** seçin
4. JSON dosyasını düzenleyin:

```json
{
  "parameters": {
    "revenuecat_api_key": {
      "defaultValue": {
        "value": "BURAYA_REVENUECAT_KEY_GIRIN"
      },
      "description": "RevenueCat iOS SDK API Key",
      "valueType": "STRING"
    },
    "fal_api_key": {
      "defaultValue": {
        "value": "BURAYA_FAL_KEY_GIRIN"
      },
      "description": "fal.ai API Key",
      "valueType": "STRING"
    },
    "enable_subscriptions": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable subscription features",
      "valueType": "BOOLEAN"
    },
    "enable_one_time_purchases": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable one-time credit purchases",
      "valueType": "BOOLEAN"
    },
    "enable_video_editing": {
      "defaultValue": {
        "value": "false"
      },
      "description": "Enable video editing features",
      "valueType": "BOOLEAN"
    },
    "enable_batch_processing": {
      "defaultValue": {
        "value": "false"
      },
      "description": "Enable batch video processing",
      "valueType": "BOOLEAN"
    },
    "max_video_size_mb": {
      "defaultValue": {
        "value": "100"
      },
      "description": "Maximum video size in MB",
      "valueType": "NUMBER"
    },
    "max_video_duration_minutes": {
      "defaultValue": {
        "value": "60"
      },
      "description": "Maximum video duration in minutes",
      "valueType": "NUMBER"
    },
    "free_user_credits": {
      "defaultValue": {
        "value": "5"
      },
      "description": "Starting credits for free users",
      "valueType": "NUMBER"
    },
    "max_retries": {
      "defaultValue": {
        "value": "3"
      },
      "description": "Maximum retry attempts for failed operations",
      "valueType": "NUMBER"
    },
    "starter_monthly_credits": {
      "defaultValue": {
        "value": "60"
      },
      "description": "Monthly credits for Starter plan",
      "valueType": "NUMBER"
    },
    "pro_monthly_credits": {
      "defaultValue": {
        "value": "180"
      },
      "description": "Monthly credits for Pro plan",
      "valueType": "NUMBER"
    },
    "ultimate_monthly_credits": {
      "defaultValue": {
        "value": "500"
      },
      "description": "Monthly credits for Ultimate plan",
      "valueType": "NUMBER"
    }
  }
}
```

5. **"Publish template"** seçin ve JSON dosyasını yükleyin
6. **"Publish changes"** butonuna tıklayın

## Test ve Doğrulama

### Test Etme

1. **Xcode'da Çalıştırın:**
   ```bash
   # Xcode'u açın
   open AutoSubtitle.xcodeproj

   # Cmd+R ile çalıştırın
   ```

2. **Console Log'larını İzleyin:**
   ```
   ✅ Firebase configured
   🚀 Starting app initialization...
   📡 Fetching Remote Config...
   📋 Remote Config values:
     RevenueCat API Key: SET (appl_xxxxx...)
     fal.ai API Key: SET (fal_xxxxx...)
     Enable Subscriptions: true
     Max Video Size: 100 MB
   ✅ Configuration validated successfully
   ✅ App initialization complete!
   ```

3. **Hata Durumunda:**
   ```
   ❌ RevenueCat API key is missing
   ❌ fal.ai API key is missing
   ❌ Configuration validation failed
   ```

### Debug Modu

Debug modunda daha detaylı log'lar görmek için:

```swift
// RemoteConfigManager.swift içinde otomatik olarak etkin
#if DEBUG
print("📋 Remote Config values:")
// ... detaylı loglar
#endif
```

### Manuel Test

Remote Config değerlerini manuel olarak test etmek için:

```swift
// Herhangi bir View'da
@EnvironmentObject var remoteConfigManager: RemoteConfigManager

var body: some View {
    VStack {
        Text("RevenueCat Key: \(remoteConfigManager.revenueCatAPIKey.isEmpty ? "NOT SET" : "SET")")
        Text("fal.ai Key: \(remoteConfigManager.falAPIKey.isEmpty ? "NOT SET" : "SET")")
        Text("Max Video Size: \(remoteConfigManager.maxVideoSizeMB) MB")
        Text("Free Credits: \(remoteConfigManager.freeUserCredits)")
    }
}
```

## Güvenlik Notları

### ✅ Yapılması Gerekenler

- API key'leri **sadece** Remote Config'de saklayın
- Production ve Development için **ayrı Firebase projeleri** kullanın
- Remote Config'i düzenli olarak yedekleyin (Export template)
- API key'leri kod içine **asla hardcode etmeyin**

### ❌ Yapılmaması Gerekenler

- API key'leri Git'e commit etmeyin
- `.plist` veya `.xcconfig` dosyalarında saklamayın
- Debug log'larında tam API key'i göstermeyin (sadece ilk 10 karakter)

## Sık Karşılaşılan Sorunlar

### 1. "API key not configured" Hatası

**Sebep:** Remote Config parametresi eksik veya yayınlanmamış

**Çözüm:**
1. Firebase Console → Remote Config kontrol edin
2. Parametrelerin doğru yazıldığından emin olun (typo olabilir)
3. **"Publish changes"** butonuna tıklamayı unutmayın
4. Uygulamayı yeniden başlatın

### 2. "Fetch timed out" Hatası

**Sebep:** İnternet bağlantısı yok veya Firebase erişilemiyor

**Çözüm:**
1. İnternet bağlantınızı kontrol edin
2. Firebase Console'da proje durumunu kontrol edin
3. Firewall veya VPN ayarlarını kontrol edin

### 3. Değişiklikler Yansımıyor

**Sebep:** Remote Config cache'lenmiş değerleri kullanıyor

**Çözüm:**
```swift
// Debug modunda cache devre dışı:
settings.minimumFetchInterval = 0

// Veya uygulamayı tamamen kapatıp açın
// Simulator: Device → Erase All Content and Settings
```

## A/B Testing (İleri Seviye)

Remote Config ile A/B testing yapabilirsiniz:

```json
// Örnek: %50 kullanıcıya farklı free credit değeri
{
  "conditions": [
    {
      "name": "test_group_a",
      "expression": "percent <= 50",
      "value": "10"
    }
  ],
  "defaultValue": "5"
}
```

## Sonraki Adımlar

1. ✅ API key'leri Remote Config'e ekleyin
2. ✅ Publish changes yapın
3. ✅ Uygulamayı çalıştırın ve log'ları kontrol edin
4. ✅ Test edin (video yükleyin, satın alma yapın)
5. 🚀 Production'a deploy edin!

## Yardım ve Destek

- **Firebase Docs:** https://firebase.google.com/docs/remote-config
- **Support:** support@autosubtitle.app

---

**Not:** API key'lerinizi kimseyle paylaşmayın ve GitHub'a commit etmeyin! 🔒
