# PetSmart Flutter Application

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.7.2+-blue.svg)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![Material Design](https://img.shields.io/badge/Material-Design-blue.svg)](https://material.io/)
[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-green.svg)](https://github.com/yourusername/pet_smart)

A comprehensive pet care management and e-commerce platform built with Flutter, featuring real-time chat, appointment booking, pet management, shopping with cart functionality, push notifications with deep linking, and secure user authentication powered by Supabase. The app supports both cats and dogs with Material Design 3 styling, Philippine Peso currency formatting, lazy loading optimization, and a complete backend integration with Row Level Security.

## 🎯 Recent Comprehensive Updates

This README documents the extensive updates and improvements made to the PetSmart Flutter application, transforming it into a production-ready, feature-complete pet care platform with modern UI/UX patterns and robust backend integration.

### 🔄 Major System Overhauls

**Authentication System Enhancements:**
- ✅ Removed Google OAuth for simplified email/password authentication
- ✅ Implemented optional email verification with auto-accept functionality
- ✅ Added mandatory profile picture validation in profile setup flow
- ✅ Integrated functional forgot password with Supabase Auth
- ✅ Enhanced persistent authentication with automatic dashboard redirect

**UI/UX Complete Redesign:**
- ✅ Applied consistent Material Design 3 styling across all screens
- ✅ Implemented SalomonBottomBar navigation with badge support
- ✅ Enhanced toast notifications with professional styling and animations
- ✅ Added conversational dialogue style throughout the app
- ✅ Implemented lazy loading optimization with skeleton screens

**Core Feature Implementation:**
- ✅ Complete pet management system with Cat/Dog limitation and comprehensive CRUD operations
- ✅ Real-time appointment booking with server-side time synchronization and operating hours validation
- ✅ Full e-commerce platform with Supabase cart integration and 4-stage order status system
- ✅ Comprehensive real-time chat system with conversation management and admin integration
- ✅ Expo push notifications with deep linking and notification preferences

**Database & Backend:**
- ✅ Comprehensive Supabase schema with 15+ tables and Row Level Security policies
- ✅ Real-time subscriptions for chat, orders, and notifications
- ✅ Philippine Peso currency formatting and timezone support
- ✅ Environment configuration system with local development and production build support

## ✅ Current Status

**Production Ready Features:**
- ✅ Complete user authentication and registration flow
- ✅ Pet management (add, edit, view multiple pets)
- ✅ Appointment booking with time slot validation
- ✅ E-commerce with shopping cart and order processing
- ✅ Real-time chat system with admin support
- ✅ Local push notifications with deep linking
- ✅ Profile management with image upload
- ✅ Purchase history and order tracking
- ✅ Comprehensive notification system
- ✅ Material Design UI throughout
- ✅ Philippine Peso currency formatting
- ✅ Supabase backend with Row Level Security

**Tested Platforms:**
- ✅ Android (API 21+)
- ✅ iOS (iOS 11+)
- ✅ Development and production builds

## 🚀 Key Features

### 🔐 Authentication & User Management
- **Secure Authentication**: Email/password login and registration via Supabase Auth (Google OAuth removed for simplified authentication)
- **Optional Email Verification**: Flexible verification system with auto-accept functionality during registration
- **Automatic Profile Setup Flow**: Mandatory profile picture validation and seamless user details collection
- **Forgot Password Integration**: Functional password reset using Supabase Auth's built-in functionality
- **Persistent Authentication**: Automatic session management with redirect to dashboard when app reopens
- **Profile Management**: Complete user profiles with bio editing, profile picture upload, and preferences
- **Privacy & Security Settings**: Comprehensive privacy controls, account deletion, and security status indicators

### 🐾 Pet Management
- **Multi-Pet Support**: Add and manage multiple pets (limited to cats and dogs only)
- **Pet Profiles**: Detailed pet information including name, type, gender, and creation date with Supabase integration
- **Pet Cards Display**: Visual pet management with Material Design styling matching 'Recently Bought' section design
- **Comprehensive Pet Management**: Clickable pet cards for editing details with consolidated Add Pet functionality
- **Search & Filter**: Advanced filtering capabilities with simplified filter interfaces (age category and date filters removed)
- **Pull-to-Refresh**: Real-time data synchronization with proper error handling and loading states
- **Dynamic Navigation**: Context-aware back navigation that returns to appropriate previous screen

### 📅 Appointment Booking System
- **Smart Scheduling**: Book appointments with operating hours validation (Monday-Friday 7:30 AM-4:00 PM, Saturday 7:30 AM-2:00 PM, Sunday closed)
- **Time Slot Management**: Real-time availability checking and slot booking with full time ranges (start time - end time) in 12-hour format
- **Appointment Status Tracking**: Limited to 'Pending', 'Completed', and 'Cancelled' status with proper database synchronization
- **Server-side Time Synchronization**: Uses Supabase's now() function for appointment expiration logic
- **Automatic Status Updates**: 'Unavailable' status for past time slots with real-time validation and clear error messages
- **Chronological Sorting**: Upcoming appointments show nearest dates first, past appointments show most recent dates first
- **Pet-Specific Appointments**: Link appointments to specific pets with comprehensive pet selection
- **Calendar Integration**: Visual calendar interface with table_calendar
- **Loading State Management**: Confirmation buttons with immediate disable, loading indicators, and duplicate request prevention

### 🛒 E-commerce & Shopping
- **Product Catalog**: Browse pet products with real-time inventory using real API calls instead of mock data
- **Shopping Cart**: Persistent cart with Supabase backend integration, real-time updates, quantity selection, and cart total calculations
- **Order Management**: Complete purchase flow with Supabase integration for orders/order_items tables and purchase history
- **Purchase History**: Detailed order history with Philippine Peso (₱) formatting showing complete orders instead of individual products
- **Order Status System**: 4-stage order status flow: Order Preparation → Pending Delivery → Order Confirmation → Completed
- **Product Search**: Enhanced search functionality with Material Design styling, real-time search suggestions, and comprehensive search across all product categories
- **Product Images**: Multi-image support with carousel display and lazy loading optimization
- **Real-time Updates**: Supabase subscriptions for orders table with automatic UI updates following chat messaging system patterns

### 💬 Real-time Chat System
- **Conversation-based Support Chat**: Complete chat system with conversation list (like ChatGPT) and subject/title input for new conversations
- **Real-time Messaging**: Live chat with Supabase real-time subscriptions, typing indicators, and message status indicators
- **Modern Chat UI**: User messages on right side, admin messages on left side with Material Design styling
- **Conversation Management**: Conversation status management (active/completed states) with disabled input for completed conversations
- **Message History**: Persistent conversation storage with comprehensive chat history system
- **Admin Integration**: Admin MessagesView with filtering/search capabilities (admin-side functionality already implemented)
- **Push Notifications**: Expo push notifications integration for real-time message alerts
- **Philippine Timezone**: Proper timezone formatting and real-time status updates

### 🔔 Push Notifications
- **Expo Push Notifications**: Comprehensive notification system using Expo Push Notifications (preferred over Firebase Cloud Messaging)
- **Real-time Notifications**: Push notifications for order status, appointment status, and admin messages
- **Deep Linking**: Navigate directly to relevant screens from notifications with automatic navigation to notifications screen when tapped
- **Notification Preferences**: User-controlled notification settings with comprehensive preference controls
- **Event-Based Notifications**: Automatic notifications for appointments, orders, and pet activities
- **Local Notifications**: Flutter local notifications for immediate alerts with enhanced toast notifications
- **Push Token Management**: Separate table for storing Expo push tokens with local .env files for enhanced security

### 🎨 UI/UX Design
- **Material Design 3**: Consistent Material Design styling across all screens (authentication, dashboard, pet management, appointments, shop)
- **SalomonBottomBar Navigation**: Modern bottom navigation with consistent app bar styling throughout the application
- **Enhanced Toast Notifications**: Professional notification system with Material Design styling, appropriate icons/colors, smooth animations, and consistent typography
- **Conversational Dialogue Style**: Friendly tone and consistent messaging patterns applied throughout the app for all key user transactions
- **Vertical Button Layout**: Consistent vertical (stacked) button layout design across all dialogs with secondary actions at top and primary/destructive actions at bottom
- **Lazy Loading Optimization**: ListView.builder pagination, FutureBuilder/StreamBuilder for async data, pull-to-refresh functionality, and skeleton screens
- **Philippine Localization**: Philippine Peso (₱) currency formatting throughout the app with conversion rate of approximately 1 USD = 50 PHP
- **Responsive Design**: Optimized for various screen sizes with clean text styling and proper Material Design patterns

## 🛠️ Technology Stack

### Frontend
- **Flutter**: 3.7.2+ - Cross-platform mobile development framework
- **Dart**: 3.7.2+ - Programming language
- **Material Design**: UI design system with consistent styling

### Backend & Services
- **Supabase**: Backend-as-a-Service providing:
  - PostgreSQL database with Row Level Security (RLS)
  - Real-time subscriptions
  - Authentication and user management
  - File storage and CDN
- **Supabase Auth**: PKCE flow authentication
- **Real-time Features**: Live chat and notifications

### Key Dependencies
- **supabase_flutter** (^2.5.0): Supabase client for Flutter with real-time subscriptions
- **salomon_bottom_bar** (^3.3.2): Modern bottom navigation with badge support
- **table_calendar** (^3.1.1): Calendar widget for appointment booking system
- **carousel_slider** (^5.0.0): Image carousels for product displays
- **flutter_local_notifications** (^18.0.1): Local push notifications with deep linking
- **image_picker** (^1.1.2): Camera and gallery access for profile pictures
- **app_links** (^6.3.2): Deep linking support for push notifications
- **permission_handler** (^11.3.1): Device permissions management
- **shared_preferences** (^2.2.2): Local data persistence and user preferences
- **cached_network_image** (^3.3.1): Optimized image loading and caching
- **badges** (^3.1.2): Notification badges for unread messages
- **font_awesome_flutter** (^10.8.0): Icon library for enhanced UI
- **http** (^1.2.2): HTTP client for API calls

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your development machine:

### Required Software
- **Flutter SDK**: Version 3.7.2 or higher
- **Dart SDK**: Version 3.7.2 or higher (included with Flutter)
- **Android Studio**: Latest stable version (for Android development)
- **VS Code**: Latest version with Flutter extension (recommended IDE)
- **Git**: For version control

### Platform-Specific Requirements

#### Android Development
- **Android SDK**: API level 21 (Android 5.0) or higher
- **Android SDK Build-Tools**: Latest version
- **Android Emulator** or physical Android device for testing

#### iOS Development (macOS only)
- **Xcode**: Latest stable version
- **iOS Simulator** or physical iOS device
- **CocoaPods**: For iOS dependency management

### Backend Requirements
- **Supabase Account**: Free account at [supabase.com](https://supabase.com)
- **Supabase Project**: With database and authentication enabled

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

The app uses a flexible configuration system that supports both local development and production builds.

#### For Development (Recommended)

1. **Copy the template file:**
   ```bash
   cp lib/config/local_config.dart.example lib/config/local_config.dart
   ```

2. **Edit `lib/config/local_config.dart` with your Supabase credentials:**
   ```dart
   class LocalConfig {
     static const String supabaseUrl = 'https://your-project-id.supabase.co';
     static const String supabaseAnonKey = 'your_anon_key_here';
   }
   ```

3. **The file is already in `.gitignore` and won't be committed to version control.**

#### For Production Builds

Use environment variables during the build process:

```bash
flutter build apk --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

#### Configuration Priority

The app checks for configuration in this order:
1. **Environment variables** (production builds)
2. **Local config file** (development)
3. **Demo mode** (graceful fallback if no config found)

#### Security Best Practices

⚠️ **Important Security Notes:**

- **Never commit `local_config.dart` to version control** (already in `.gitignore`)
- Use different credentials for development, staging, and production
- Rotate API keys regularly
- Enable Supabase Row Level Security (RLS) policies
- Use secure environment variable services for production deployments

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
│   ├── auth/                    # Authentication & Registration
│   │   ├── auth.dart           # Main auth screen with AuthWrapper
│   │   ├── login.dart          # Login functionality with enhanced error handling
│   │   ├── register.dart       # User registration with optional email verification
│   │   ├── otp_verification.dart # Email verification (optional)
│   │   ├── user_details.dart   # User details collection
│   │   ├── profile_setup.dart  # Profile setup with mandatory image upload
│   │   └── email_verification_*.dart # Email verification flow components
│   ├── components/             # Reusable UI Components
│   │   ├── nav_bar.dart        # SalomonBottomBar navigation with badges
│   │   ├── cart_service.dart   # Shopping cart management with Supabase
│   │   ├── enhanced_toasts.dart # Professional toast notifications
│   │   ├── enhanced_dialogs.dart # Material Design dialog components
│   │   ├── search_service.dart # Enhanced search functionality
│   │   └── skeleton_screens.dart # Lazy loading skeleton components
│   ├── config/                 # Configuration Management
│   │   ├── app_config.dart     # Main configuration handler
│   │   ├── local_config.dart.example # Template for local config
│   │   └── README.md           # Configuration setup guide
│   ├── models/                 # Data Models
│   │   ├── chat_message.dart   # Chat message model
│   │   ├── conversation.dart   # Conversation model
│   │   └── notification.dart   # Notification model
│   ├── pages/                  # Main Application Screens
│   │   ├── account/            # Account Management
│   │   │   ├── all_pets.dart   # Pet management
│   │   │   ├── add_pet.dart    # Add new pet
│   │   │   ├── pet_details.dart # Pet details view
│   │   │   └── purchase_history.dart # Order history
│   │   ├── appointment/        # Appointment System
│   │   │   ├── appointment_list.dart # Appointment management
│   │   │   ├── pet_selection.dart # Pet selection for appointments
│   │   │   └── time_selection.dart # Time slot selection
│   │   ├── messages/           # Chat System
│   │   │   ├── direct_chat_admin.dart # Main chat interface
│   │   │   ├── conversation_list_page.dart # Chat conversations
│   │   │   └── widgets/        # Chat UI components
│   │   ├── setting/            # Settings & Preferences
│   │   │   ├── account_information.dart # Profile editing
│   │   │   ├── address_book.dart # Address management
│   │   │   ├── notifications.dart # Notification settings
│   │   │   └── privacy_security.dart # Privacy controls
│   │   └── shop/               # E-commerce Features
│   │       ├── dashboard.dart  # Main shop screen
│   │       ├── item_detail.dart # Product details
│   │       ├── search_results.dart # Search results
│   │       ├── new_arrivals_page.dart # New products
│   │       └── top_selling_page.dart # Popular products
│   ├── services/               # Business Logic & APIs
│   │   ├── appointment_service.dart # Appointment management with server-side validation
│   │   ├── chat_service.dart   # Real-time chat with Supabase subscriptions
│   │   ├── notification_service.dart # Comprehensive notification handling
│   │   ├── push_notification_service.dart # Expo push notifications
│   │   ├── realtime_notification_service.dart # Real-time notification updates
│   │   ├── product_service.dart # Product management with real API calls
│   │   ├── order_service.dart  # Order processing with 4-stage status system
│   │   ├── navigation_service.dart # Deep linking & navigation
│   │   ├── profile_completion_service.dart # Profile management
│   │   ├── address_service.dart # Address management
│   │   ├── lazy_loading_service.dart # Lazy loading optimization
│   │   ├── liked_products_service.dart # Wishlist functionality
│   │   ├── search_history_service.dart # Search history management
│   │   ├── unread_message_service.dart # Unread message tracking
│   │   └── deep_link_service.dart # Deep linking for notifications
│   ├── utils/                  # Utility Functions
│   │   └── currency_formatter.dart # Philippine Peso formatting
│   └── main.dart              # Application entry point
├── assets/                    # Static Assets
│   └── (images, fonts, etc.)
├── android/                   # Android Configuration
├── ios/                       # iOS Configuration
├── test/                      # Unit & Widget Tests
├── database_setup.sql         # Comprehensive Supabase database schema
├── database_migration_conversation_management.sql # Conversation management migration
├── CHAT_SYSTEM_IMPLEMENTATION.md # Chat system documentation
├── CLIENT_SIDE_MESSAGING_IMPLEMENTATION.md # Client-side messaging guide
├── NOTIFICATION_SYSTEM_README.md # Notification system guide
├── DEEP_LINKING_IMPLEMENTATION.md # Deep linking guide
├── GOOGLE_OAUTH_ANDROID_SETUP.md # Google OAuth setup guide
├── NATIVE_OAUTH_MIGRATION.md # OAuth migration documentation
├── .env.template             # Environment variables template
├── .gitignore               # Git ignore rules
└── pubspec.yaml            # Project dependencies & configuration
```

## 🗄️ Database Schema Overview

The PetSmart application uses a comprehensive Supabase database schema with Row Level Security (RLS) policies to ensure data protection and proper user access control.

### Core Database Tables

**User Management:**
- **profiles**: Extended user profile information (username, bio, profile_pic, phone_number, created_at)
- **auth.users**: Managed by Supabase Auth (automatic user authentication)

**Pet Management:**
- **pets**: Pet information (name, type, gender, user_id, created_at) - limited to 'Cat' and 'Dog' types
- **liked_items**: User's liked products for wishlist functionality

**Appointment System:**
- **appointments**: Appointment booking (user_id, pet_id, date, time, status, created_at)
- **appointment_slots**: Available time slots with operating hours validation

**E-commerce:**
- **products**: Product catalog (name, description, price, category, stock_quantity, average_rating)
- **product_images**: Product image management with multiple images per product
- **cart_items**: Shopping cart persistence (user_id, product_id, quantity, created_at)
- **orders**: Order tracking (user_id, total_amount, status, address, created_at) - 4-stage status system
- **order_items**: Order line items (order_id, product_id, quantity, price)
- **addresses**: User delivery addresses (label, full_address, phone_number, is_default)

**Communication System:**
- **conversations**: Chat conversation management (user_id, admin_id, status, last_message_at, unread_count)
- **messages**: Chat messages with conversation support (conversation_id, content, is_from_user, read_status, created_at)
- **typing_indicators**: Real-time typing status for chat system

**Notification System:**
- **notifications**: In-app notifications (user_id, title, message, type, read_status, created_at)
- **notification_preferences**: User notification settings and preferences
- **push_tokens**: Expo push notification tokens for real-time notifications

### Row Level Security (RLS) Implementation

All tables implement comprehensive RLS policies ensuring users can only access their authorized data:

```sql
-- Example: Users can only view their own pets
CREATE POLICY "Users can view own pets" ON pets
  FOR SELECT USING (auth.uid() = user_id);

-- Example: Users can only manage their own cart items
CREATE POLICY "Users can manage own cart" ON cart_items
  FOR ALL USING (auth.uid() = user_id);

-- Example: Users can only see their own orders
CREATE POLICY "Users can view own orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);
```

## 🗄️ Database Setup (Supabase)

### 1. Create Supabase Project

1. Go to [Supabase](https://supabase.com/) and create a new account
2. Create a new project
3. Note down your project URL and API keys from **Project Settings > API**

### 2. Database Schema

The application uses a comprehensive database schema. Run the provided SQL script to set up all required tables:

```bash
# Execute the database setup script in your Supabase SQL Editor
cat database_setup.sql
```

#### Core Tables

**User Management:**
- **profiles**: Extended user profile information (username, bio, profile_pic)
- **auth.users**: Managed by Supabase Auth (automatic)

**Pet Management:**
- **pets**: Pet information (name, type, gender, user_id)
- **liked_items**: User's liked products

**Appointment System:**
- **appointments**: Appointment booking (user_id, pet_id, date, time, status)
- **appointment_slots**: Available time slots

**E-commerce:**
- **products**: Product catalog (name, description, price, category)
- **product_images**: Product image management
- **cart_items**: Shopping cart persistence
- **orders**: Order tracking (user_id, total_amount, status, address)
- **order_items**: Order line items (order_id, product_id, quantity, price)
- **addresses**: User delivery addresses

**Communication:**
- **messages**: Chat messages with conversation support
- **conversations**: Chat conversation management
- **typing_indicators**: Real-time typing status

**Notifications:**
- **notifications**: In-app notifications
- **notification_preferences**: User notification settings
- **push_tokens**: Push notification tokens (for future Expo integration)

### 3. Row Level Security (RLS)

All tables have RLS enabled with appropriate policies. Examples:

```sql
-- Users can only view their own pets
CREATE POLICY "Users can view own pets" ON pets
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only manage their own cart items
CREATE POLICY "Users can manage own cart" ON cart_items
  FOR ALL USING (auth.uid() = user_id);

-- Users can only see their own orders
CREATE POLICY "Users can view own orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);
```

### 4. Real-time Subscriptions

Enable real-time for chat functionality:

```sql
-- Enable real-time for messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_indicators;
```

### 5. Authentication Configuration

In your Supabase dashboard:

1. **Authentication > Settings**:
   - Enable email confirmations (optional)
   - Configure email templates
   - Set up custom SMTP (recommended for production)

2. **Authentication > URL Configuration**:
   - Add your app's deep link URLs for email verification

## � Running the Application

### Development Mode

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Run with hot reload (default in debug mode)
flutter run --hot
```

### Production Builds

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Google Play)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# With environment variables
flutter build apk --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart

# Integration tests (if available)
flutter drive --target=test_driver/app.dart
```

## 🔧 Configuration & Services

### Push Notifications

The app includes a comprehensive local notification system:

- **Local Notifications**: Immediate notifications for app events
- **Deep Linking**: Navigate to specific screens from notifications
- **Notification Preferences**: User-controlled settings
- **Event Triggers**: Automatic notifications for appointments, orders, pet activities

### Chat System

Real-time chat with customer support:

- **Real-time Messaging**: Live chat with typing indicators
- **Message History**: Persistent conversation storage
- **File Attachments**: Support for images and files
- **Admin Interface**: Customer support chat management

### Operating Hours

**Appointment Booking Hours:**
- Monday-Friday: 7:30 AM - 4:00 PM
- Saturday: 7:30 AM - 2:00 PM
- Sunday: Closed

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Configuration Issues

**Problem**: App shows "configuration error" or runs in demo mode

**Solutions**:
- Verify `lib/config/local_config.dart` exists with correct Supabase credentials
- Check that Supabase project is active and accessible
- Ensure API keys are valid and not expired

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

# Update dependencies
flutter pub upgrade
```

#### Supabase Connection Issues

**Problem**: Cannot connect to Supabase or database errors

**Solutions**:
- Verify Supabase project URL and API keys
- Check that database tables exist (run `database_setup.sql`)
- Ensure Row Level Security policies are properly configured
- Verify network connectivity

#### Device Connection Issues

**Problem**: Device not detected

**Solutions**:
- Enable USB debugging on Android device
- Try different USB cable or port
- Restart ADB: `adb kill-server && adb start-server`
- Check device drivers on Windows

#### Performance Issues

**Problem**: App runs slowly or crashes

**Solutions**:
- Run in release mode: `flutter run --release`
- Check for memory leaks in code
- Optimize image assets and reduce file sizes
- Use `flutter analyze` to identify performance issues
- Monitor device logs: `flutter logs`

## 📚 Additional Documentation

### Project-Specific Guides
- **[Chat System Implementation](CHAT_SYSTEM_IMPLEMENTATION.md)**: Comprehensive guide for the real-time chat system
- **[Client-Side Messaging Implementation](CLIENT_SIDE_MESSAGING_IMPLEMENTATION.md)**: Complete client-side messaging system documentation
- **[Notification System](NOTIFICATION_SYSTEM_README.md)**: Local notification system setup and usage
- **[Deep Linking Implementation](DEEP_LINKING_IMPLEMENTATION.md)**: Push notification deep linking guide
- **[Database Setup](database_setup.sql)**: Complete Supabase database schema and setup
- **[Database Migration](database_migration_conversation_management.sql)**: Conversation management database migration
- **[Google OAuth Setup](GOOGLE_OAUTH_ANDROID_SETUP.md)**: Google OAuth configuration for Android
- **[Native OAuth Migration](NATIVE_OAUTH_MIGRATION.md)**: Migration guide from web-based to native Android OAuth
- **[Configuration Guide](lib/config/README.md)**: Environment configuration and security setup

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

We welcome contributions to the PetSmart Flutter application! Please follow these guidelines:

### Development Guidelines

1. **Code Style**: Follow Dart/Flutter conventions and use `flutter format .` before committing
2. **Testing**: Write tests for new features and ensure existing tests pass
3. **Documentation**: Update documentation for any new features or changes
4. **Security**: Never commit sensitive credentials or API keys

### Contribution Process

1. **Fork the repository** and clone your fork locally
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** following the coding standards
4. **Test thoroughly** on both Android and iOS (if possible)
5. **Run code analysis**: `flutter analyze` and fix any issues
6. **Format your code**: `flutter format .`
7. **Commit your changes**: `git commit -m 'Add: brief description of feature'`
8. **Push to your branch**: `git push origin feature/your-feature-name`
9. **Submit a pull request** with a clear description of changes

### Code Review Process

- All pull requests require review before merging
- Ensure CI/CD checks pass
- Address any feedback from reviewers
- Keep pull requests focused and atomic

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
