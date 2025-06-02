# 🔧 Google OAuth Android Client Setup Guide

## ❌ **Current Issue**

You downloaded a **Desktop Application** client secret, but we need an **Android Application** client for native OAuth to work.

**Downloaded file type**: Desktop/Installed Application
```json
{"installed":{"client_id":"948715267913-3p7nvotj331ov7itl13t2229162d6mg6.apps.googleusercontent.com",...}}
```

**Required**: Android Application OAuth client with proper `google-services.json`

## ✅ **Firebase/Google Services Configuration Complete**

I've updated your project with the proper Firebase configuration following the official documentation:

### **Updated Files**:
- ✅ `android/build.gradle.kts` - Added Google Services plugin
- ✅ `android/app/build.gradle.kts` - Added Firebase BoM and dependencies
- ✅ `android/settings.gradle.kts` - Updated Kotlin version for compatibility
- ✅ Build tested and working

## ✅ **Solution: Create Android OAuth Client**

### **Step 1: Access Google Cloud Console**

1. Go to: https://console.cloud.google.com/
2. Select project: **`sunny-truth-460708-q6`**
3. Navigate to: **APIs & Services** > **Credentials**

### **Step 2: Create Android OAuth Client**

1. **Click**: "Create Credentials" > "OAuth client ID"
2. **Application type**: Select **"Android"** (NOT Desktop)
3. **Name**: `PetSmart Android App`
4. **Package name**: `com.example.pet_smart`
5. **SHA-1 certificate fingerprint**: `34:DE:C5:0A:17:D1:7C:76:83:72:41:2E:7C:21:C6:B3:B3:5D:9F:C2`
6. **Click**: "Create"

### **Step 3: Enable Required APIs**

Make sure these APIs are enabled:
1. **Google+ API** (for profile information)
2. **Google Sign-In API**

To enable:
1. Go to: **APIs & Services** > **Library**
2. Search for and enable each API

### **Step 4: Download google-services.json**

**Option A: From Project Settings**
1. Click the **gear icon** (Project Settings)
2. Go to **General** tab
3. Scroll to **"Your apps"** section
4. Click **Android icon**
5. Download **`google-services.json`**

**Option B: From Firebase Console**
1. Go to: https://console.firebase.google.com/
2. Select your project: `sunny-truth-460708-q6`
3. Click **gear icon** > **Project settings**
4. Go to **General** tab
5. Scroll to **"Your apps"** section
6. Download **`google-services.json`**

### **Step 5: Replace Configuration File**

1. **Replace** the file at: `android/app/google-services.json`
2. **Use the downloaded file** (don't edit manually)

### **Step 6: Update Supabase Configuration**

1. Go to your **Supabase project dashboard**
2. Navigate to: **Authentication** > **Providers** > **Google**
3. **Update Client ID** with the **web client ID** from your `google-services.json`
4. **Save** the configuration

## 🔍 **Verification Steps**

### **Check Your google-services.json**

The correct file should look like this:
```json
{
  "project_info": {
    "project_number": "948715267913",
    "project_id": "sunny-truth-460708-q6"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:948715267913:android:REAL_APP_ID",
        "android_client_info": {
          "package_name": "com.example.pet_smart"
        }
      },
      "oauth_client": [
        {
          "client_id": "948715267913-ANDROID_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.pet_smart",
            "certificate_hash": "34dec50a17d17c7683724127c21c6b3b35d9fc2"
          }
        },
        {
          "client_id": "948715267913-WEB_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "REAL_API_KEY_FROM_GOOGLE"
        }
      ]
    }
  ]
}
```

### **Key Differences**
- ✅ **client_type: 1** = Android client
- ✅ **client_type: 3** = Web client (for Supabase)
- ✅ **Real API key** (not placeholder)
- ✅ **Real mobile SDK app ID**

## 🧪 **Testing After Setup**

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

2. **Test Google Sign-In**:
   - Tap "Sign in with Google"
   - Should show **native Android account picker**
   - Should **NOT** open browser/web view
   - Should complete authentication within app

## 🚨 **Common Issues & Solutions**

### **Issue**: "ApiException: 10" (DEVELOPER_ERROR)
**Solution**: SHA-1 fingerprint doesn't match
- Verify SHA-1 in Google Cloud Console matches: `34:DE:C5:0A:17:D1:7C:76:83:72:41:2E:7C:21:C6:B3:B3:5D:9F:C2`

### **Issue**: "No ID Token received"
**Solution**: Wrong google-services.json file
- Ensure you downloaded the Android app configuration
- Check that package name matches exactly

### **Issue**: "Sign-in cancelled"
**Solution**: Missing Google Play Services
- Test on device with Google Play Services
- Ensure Google account is added to device

## 📋 **Checklist**

- [ ] Created **Android** OAuth client (not Desktop)
- [ ] Used correct package name: `com.example.pet_smart`
- [ ] Used correct SHA-1: `19:9C:02:4E:83:59:4A:8C:FC:48:13:B9:1D:A7:AD:B4:29:BA:4C:48`
- [ ] Downloaded proper `google-services.json`
- [ ] Replaced file in `android/app/google-services.json`
- [ ] Updated Supabase Google OAuth configuration
- [ ] Enabled required Google APIs
- [ ] Tested on device with Google Play Services

## 🎯 **Expected Result**

After proper setup:
- ✅ Native Google account picker appears
- ✅ No browser/web view opens
- ✅ Authentication completes within app
- ✅ User redirected to dashboard
- ✅ Debug logs show successful authentication

The key is creating the **Android OAuth client** instead of using the Desktop client you downloaded.
