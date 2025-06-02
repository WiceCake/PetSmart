# Google Services Setup Guide

## 🎯 **STEP 1: Get Your Firebase Project Information**

Since you already registered the app in Firebase, you need to get the following information from your Firebase Console:

### **Go to Firebase Console**:
1. Visit: https://console.firebase.google.com/
2. Select your project
3. Click the **gear icon** (Project Settings)
4. Go to **General** tab

### **Get Project Information**:
- **Project ID**: (found in Project Settings)
- **Project Number**: (found in Project Settings)
- **Web App Config**: Click on your web app to get the config

### **Get Android App Information**:
1. In Project Settings, scroll to **"Your apps"** section
2. Click on your Android app (package: `com.example.pet_smart`)
3. Download the `google-services.json` file

## 🎯 **STEP 2: Place the google-services.json File**

1. **Download** the `google-services.json` file from Firebase Console
2. **Place it** in: `android/app/google-services.json`
3. **Replace** the existing template file

## 🎯 **STEP 3: Get Client IDs for Supabase**

From the downloaded `google-services.json` file, you need to extract:

### **Web Client ID** (for Supabase):
- Look for `"client_type": 3` in the oauth_client array
- Copy the `client_id` value
- This goes in your `.env` file as `GOOGLE_WEB_CLIENT_ID`

### **Android Client ID** (automatically used by Firebase):
- Look for `"client_type": 1` in the oauth_client array
- This is automatically used by the Google Sign-In library

## 🎯 **STEP 4: Update Environment Variables**

Update your `assets/.env` file with the Web Client ID:

```
GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com
```

## 🎯 **STEP 5: Configure Supabase Dashboard**

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** > **Providers**
3. Enable **Google** provider
4. Add your **Web Client ID** and **Client Secret**
5. Set redirect URL to: `https://YOUR_SUPABASE_PROJECT.supabase.co/auth/v1/callback`

## 🚀 **Ready to Test!**

Once you complete these steps:
1. The app will automatically detect the Firebase configuration
2. Google Sign-In will use native Android authentication
3. Supabase will handle the backend authentication
4. Everything should work seamlessly!

## 📋 **Quick Checklist**

- [ ] Downloaded `google-services.json` from Firebase Console
- [ ] Placed file in `android/app/google-services.json`
- [ ] Updated `.env` with Web Client ID
- [ ] Configured Google provider in Supabase Dashboard
- [ ] Ready to test Google Sign-In!
