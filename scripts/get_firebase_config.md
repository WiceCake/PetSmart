# 🔥 Get Firebase Configuration

## **STEP 1: Download google-services.json**

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `sunny-truth-460708-q6`
3. **Click gear icon** → **Project settings**
4. **Go to General tab**
5. **Scroll to "Your apps" section**
6. **Find your Android app** with package `com.example.pet_smart`
7. **Click "Download google-services.json"**

## **STEP 2: Replace the File**

1. **Take the downloaded file**
2. **Replace**: `android/app/google-services.json`
3. **Make sure the package name is**: `com.example.pet_smart`

## **STEP 3: Verify Client IDs**

Open the downloaded `google-services.json` and verify:

### **Android Client ID** (client_type: 1):
Should match: `34207114766-ik43ogar99t648kshmsgiotn33n60ccv.apps.googleusercontent.com`

### **Web Client ID** (client_type: 3):
Should match: `34207114766-60j6hd2n9ofebiilp4foogib0hod4a2f.apps.googleusercontent.com`

### **SHA-1 Certificate**:
Should match: `199c024e83594a8cfc4813b91da7adb429ba4c48`

## **STEP 4: Get Missing Information**

From the downloaded file, you need:

1. **mobilesdk_app_id**: Copy this value
2. **api_key**: Copy the current_key value

## **STEP 5: Update the File**

If any values are missing, update the `android/app/google-services.json` file with the correct values.

## **🚀 Ready to Test!**

Once you have the correct `google-services.json` file:
1. Run the app
2. Try Google Sign-In
3. It should work with native Android authentication!

## **📋 Expected File Structure**

Your `google-services.json` should look like:

```json
{
  "project_info": {
    "project_number": "34207114766",
    "project_id": "sunny-truth-460708-q6"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:34207114766:android:ACTUAL_APP_ID",
        "android_client_info": {
          "package_name": "com.example.pet_smart"
        }
      },
      "oauth_client": [
        {
          "client_id": "34207114766-ik43ogar99t648kshmsgiotn33n60ccv.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.pet_smart",
            "certificate_hash": "199c024e83594a8cfc4813b91da7adb429ba4c48"
          }
        },
        {
          "client_id": "34207114766-60j6hd2n9ofebiilp4foogib0hod4a2f.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "ACTUAL_API_KEY_FROM_FIREBASE"
        }
      ]
    }
  ]
}
```
