# PetSmart Flutter Application

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A comprehensive pet care management application built with Flutter, featuring appointment booking, pet management, shopping, and user authentication powered by Supabase.

## 🚀 Features

- **User Authentication**: Secure login/registration with email verification
- **Pet Management**: Add, edit, and manage multiple pets with detailed profiles
- **Appointment Booking**: Schedule and manage veterinary appointments
- **Shopping**: Browse and purchase pet products with cart functionality
- **User Profile**: Manage personal information and preferences
- **Real-time Chat**: Direct messaging with administrators
- **Payment Integration**: Secure payment processing for purchases

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your development machine:

### Required Software

- **Flutter SDK**: Version 3.0.0 or higher
- **Dart SDK**: Version 3.0.0 or higher (included with Flutter)
- **Android Studio**: Latest stable version (for Android development)
- **VS Code**: Latest version (alternative IDE)
- **Git**: For version control

### Platform-Specific Requirements

#### Android Development
- **Android SDK**: API level 21 (Android 5.0) or higher
- **Android SDK Build-Tools**: Latest version
- **Android Emulator** or physical Android device

#### iOS Development (macOS only)
- **Xcode**: Latest stable version
- **iOS Simulator** or physical iOS device
- **CocoaPods**: For iOS dependency management

### Additional Tools
- **Chrome Browser**: For web debugging (if web support is enabled)
- **Supabase Account**: For backend services

## 🛠️ Project Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/pet_smart.git
cd pet_smart
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Installation

```bash
flutter doctor
```

Ensure all checkmarks are green. If there are issues, follow the suggested fixes.

### 4. Environment Configuration

#### Create Environment File

Create a `.env` file in the root directory of the project:

```bash
touch .env
```

#### Configure Environment Variables

Add the following variables to your `.env` file:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# App Configuration
APP_NAME=PetSmart
APP_VERSION=1.0.0
DEBUG_MODE=true

# API Keys (if applicable)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
PAYMENT_GATEWAY_KEY=your_payment_gateway_key
```

#### Security Best Practices

⚠️ **Important Security Notes:**

- Never commit the `.env` file to version control
- Use different environment files for development, staging, and production
- Rotate API keys regularly
- Use Supabase Row Level Security (RLS) policies
- Store sensitive keys in secure environment variable services for production

#### Environment Template

Create a `.env.template` file for team members:

```env
# Copy this file to .env and fill in your actual values

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# App Configuration
APP_NAME=PetSmart
APP_VERSION=1.0.0
DEBUG_MODE=true

# Optional API Keys
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
PAYMENT_GATEWAY_KEY=your_payment_gateway_key
```

## 📱 Device Testing Setup

### Android Device Setup

#### 1. Enable Developer Options
1. Go to **Settings** > **About phone**
2. Tap **Build number** 7 times
3. Developer options will be enabled

#### 2. Enable USB Debugging
1. Go to **Settings** > **Developer options**
2. Enable **USB debugging**
3. Enable **Install via USB** (if available)

#### 3. Connect Device
1. Connect your Android device via USB cable
2. Allow USB debugging when prompted on device
3. Verify connection:
   ```bash
   flutter devices
   ```

#### 4. Run on Device
```bash
flutter run
```

### iOS Device Setup (macOS only)

#### 1. Enable Developer Mode
1. Connect device to Mac
2. Open Xcode
3. Go to **Window** > **Devices and Simulators**
4. Select your device and enable it for development

#### 2. Trust Developer Certificate
1. On device: **Settings** > **General** > **VPN & Device Management**
2. Trust your developer certificate

#### 3. Run on Device
```bash
flutter run
```

## 🔧 Flutter Commands Reference

### Essential Development Commands

```bash
# Get dependencies
flutter pub get

# Run app in debug mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release

# Hot reload (during development)
# Press 'r' in terminal or save files in IDE

# Hot restart
# Press 'R' in terminal
```

### Build Commands

```bash
# Build APK for Android
flutter build apk

# Build App Bundle for Google Play
flutter build appbundle

# Build for iOS (macOS only)
flutter build ios

# Build for web (if enabled)
flutter build web
```

### Testing Commands

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Debugging Commands

```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Clean build cache
flutter clean

# Upgrade Flutter SDK
flutter upgrade

# Check for outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

## 🗂️ Project Structure

```
pet_smart/
├── lib/
│   ├── auth/                 # Authentication screens
│   ├── components/           # Reusable UI components
│   ├── pages/               # Main application screens
│   │   ├── account/         # Account management
│   │   ├── appointment/     # Appointment booking
│   │   ├── shop/           # Shopping features
│   │   └── setting/        # Settings screens
│   ├── services/           # API and business logic
│   └── main.dart          # Application entry point
├── assets/                # Images, fonts, and other assets
├── android/              # Android-specific configuration
├── ios/                  # iOS-specific configuration
├── test/                 # Unit and widget tests
├── .env                  # Environment variables (not in repo)
├── .env.template         # Environment template
└── pubspec.yaml         # Project dependencies
```

## 🗄️ Database Setup (Supabase)

### 1. Create Supabase Project

1. Go to [Supabase](https://supabase.com/) and create a new account
2. Create a new project
3. Note down your project URL and API keys

### 2. Database Schema

The application requires the following tables in your Supabase database:

#### Core Tables
- **profiles**: User profile information
- **pets**: Pet management data
- **appointments**: Appointment booking system
- **products**: Shop product catalog
- **product_images**: Product image management
- **orders**: Order tracking
- **order_items**: Order line items

#### Authentication Tables
- **auth.users**: Managed by Supabase Auth (automatic)

### 3. Row Level Security (RLS)

Enable RLS on all tables and create appropriate policies:

```sql
-- Example RLS policy for pets table
CREATE POLICY "Users can view own pets" ON pets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own pets" ON pets
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 4. Environment Variables

Add your Supabase credentials to the `.env` file:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Flutter Doctor Issues

**Problem**: Flutter doctor shows issues
```bash
flutter doctor
```

**Solutions**:
- **Android SDK not found**: Install Android Studio and SDK
- **Xcode not found**: Install Xcode from Mac App Store (macOS only)
- **VS Code not found**: Install VS Code and Flutter extension

#### Device Connection Issues

**Problem**: Device not detected
```bash
flutter devices
```

**Solutions**:
- Enable USB debugging on Android device
- Try different USB cable
- Restart ADB: `adb kill-server && adb start-server`
- Check device drivers on Windows

#### Build Failures

**Problem**: Build fails with dependency errors

**Solutions**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Clear pub cache if needed
flutter pub cache repair
```

#### Supabase Connection Issues

**Problem**: Cannot connect to Supabase

**Solutions**:
- Verify `.env` file exists and has correct values
- Check Supabase project status
- Verify API keys are not expired
- Check network connectivity

#### Hot Reload Not Working

**Problem**: Hot reload doesn't update the app

**Solutions**:
- Use hot restart instead: Press `R` in terminal
- Check if you're modifying main() function
- Restart the app completely: `Ctrl+C` then `flutter run`

### Performance Issues

**Problem**: App runs slowly

**Solutions**:
- Run in release mode: `flutter run --release`
- Check for memory leaks in code
- Optimize image assets
- Use `flutter analyze` to find performance issues

## 📚 Additional Resources

### Flutter Documentation
- [Flutter Official Docs](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)

### Supabase Documentation
- [Supabase Docs](https://supabase.com/docs)
- [Supabase Flutter Client](https://supabase.com/docs/reference/dart/introduction)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

### Development Tools
- [Flutter Inspector](https://docs.flutter.dev/development/tools/flutter-inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and commit: `git commit -m 'Add feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Search existing [GitHub Issues](https://github.com/yourusername/pet_smart/issues)
3. Create a new issue with detailed information
4. Contact the development team

---

**Happy Coding! 🐾**
