# OAuth Configuration Fix Guide

The Google and Facebook OAuth authentication is failing due to configuration issues. Here's how to fix them:

## 🔍 **Issue Identified**

**Google Sign-In Error**: `ApiException: 10` (DEVELOPER_ERROR)
- This means the SHA-1 fingerprint and package name don't match the Google Cloud Console configuration

**Your App Details**:
- **Package Name**: `com.example.pet_smart`
- **SHA-1 Fingerprint**: `34:DE:C5:0A:17:D1:7C:76:83:72:41:2E:7C:21:C6:B3:B3:5D:9F:C2`

## 🛠️ **Step 1: Fix Google OAuth Configuration**

### Option A: Update Google Cloud Console (Recommended)

1. **Go to Google Cloud Console**:
   - Visit: https://console.cloud.google.com/
   - Select your project (or create a new one)

2. **Enable Google Sign-In API**:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Sign-In API" and enable it

3. **Configure OAuth Consent Screen**:
   - Go to "APIs & Services" > "OAuth consent screen"
   - Fill in required fields (App name, User support email, etc.)

4. **Create/Update OAuth 2.0 Client ID**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - Select "Android" as application type
   - **Package Name**: `com.example.pet_smart`
   - **SHA-1 Certificate Fingerprint**: `34:DE:C5:0A:17:D1:7C:76:83:72:41:2E:7C:21:C6:B3:B3:5D:9F:C2`
   - Save and copy the Client ID

5. **Update Supabase Configuration**:
   - Go to your Supabase project dashboard
   - Navigate to "Authentication" > "Providers" > "Google"
   - Replace the Client ID with the new one from Google Cloud Console
   - Save the configuration

### Option B: Update Supabase to Match Existing Google Project

If you already have a Google Cloud project configured:

1. **Get the correct package name and SHA-1** from your Google Cloud Console
2. **Update your Flutter app**:
   - Change package name in `android/app/build.gradle.kts`
   - Update `applicationId` to match Google Cloud Console
3. **Regenerate SHA-1** if needed and update Google Cloud Console

## 🛠️ **Step 2: Fix Facebook OAuth Configuration**

### Configure Facebook App

1. **Go to Facebook Developers**:
   - Visit: https://developers.facebook.com/
   - Go to your app or create a new one

2. **Add Android Platform**:
   - In your Facebook app dashboard, go to "Settings" > "Basic"
   - Click "Add Platform" > "Android"
   - **Package Name**: `com.example.pet_smart`
   - **Class Name**: `com.example.pet_smart.MainActivity`
   - **Key Hashes**: Convert SHA-1 to Base64 format

3. **Convert SHA-1 to Key Hash**:
   ```bash
   # Use this command to convert SHA-1 to Facebook Key Hash
   echo "34:DE:C5:0A:17:D1:7C:76:83:72:41:2E:7C:21:C6:B3:B3:5D:9F:C2" | xxd -r -p | openssl base64
   ```

4. **Update Supabase Facebook Configuration**:
   - Go to Supabase project dashboard
   - Navigate to "Authentication" > "Providers" > "Facebook"
   - Update with correct Facebook App ID and App Secret

## 🛠️ **Step 3: Add Required Configuration Files**

### Add Google Services Configuration

1. **Download google-services.json**:
   - From Google Cloud Console > "APIs & Services" > "Credentials"
   - Download the `google-services.json` file

2. **Place the file**:
   - Copy `google-services.json` to `android/app/` directory

3. **Update build.gradle.kts**:
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("com.google.gms.google-services") // Add this line
       id("dev.flutter.flutter-gradle-plugin")
   }
   ```

4. **Update project-level build.gradle.kts**:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0") // Add this line
   }
   ```

## 🛠️ **Step 4: Update Android Configuration**

### Update AndroidManifest.xml

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Add inside <application> tag -->
<meta-data
    android:name="com.google.android.gms.version"
    android:value="@integer/google_play_services_version" />

<!-- Facebook Configuration -->
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id" />
<meta-data
    android:name="com.facebook.sdk.ClientToken"
    android:value="@string/facebook_client_token" />
```

### Add strings.xml

Create `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```

## 🛠️ **Step 5: Test the Configuration**

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean && cd ..
   flutter run
   ```

2. **Test OAuth flows**:
   - Try Google Sign-In
   - Try Facebook Login
   - Check debug logs for any remaining errors

## 🔧 **Quick Fix Alternative**

If you want a quick temporary fix for testing:

1. **Use Supabase's built-in OAuth URLs** instead of native sign-in
2. **Update OAuth service** to use web-based OAuth flow
3. **This bypasses the SHA-1 fingerprint requirement** but provides less seamless UX

## 📞 **Need Help?**

If you encounter issues:

1. **Check debug logs** for specific error messages
2. **Verify all configuration values** match between platforms
3. **Ensure all required files** are in place
4. **Test on a physical device** (OAuth may not work on emulators)

## ✅ **Verification Checklist**

- [ ] Google Cloud Console configured with correct package name and SHA-1
- [ ] Supabase Google provider updated with new Client ID
- [ ] Facebook app configured with correct package name and key hash
- [ ] Supabase Facebook provider updated with App ID and Secret
- [ ] google-services.json file added to android/app/
- [ ] Build files updated with Google Services plugin
- [ ] AndroidManifest.xml updated with required meta-data
- [ ] strings.xml created with Facebook configuration
- [ ] App cleaned and rebuilt
- [ ] Tested on physical device

Once these steps are completed, the OAuth authentication should work properly!
