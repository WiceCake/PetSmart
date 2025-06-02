# Deep Linking Implementation for Push Notifications

## Overview

This document describes the deep linking functionality implemented for push notifications in the PetSmart Flutter app. When users tap on push notifications, the app automatically navigates to relevant screens based on the notification type.

## ✅ Features Implemented

### 1. **Automatic Navigation Based on Notification Type**
- **Order notifications** → Navigate to Purchase History page
- **Appointment notifications** → Navigate to Appointment List page  
- **Pet notifications** → Navigate to All Pets page
- **Promotional notifications** → Navigate to Shop Dashboard
- **System notifications** → Navigate to Notifications List page

### 2. **Authentication-Aware Navigation**
- If user is not logged in when tapping notification → Set pending navigation
- After successful login → Automatically execute pending navigation
- Seamless user experience across different app states

### 3. **Cross-Platform Compatibility**
- Works on Android and iOS
- Handles app states: terminated, background, and foreground
- Consistent behavior across different scenarios

### 4. **Robust Error Handling**
- Fallback to notifications page if navigation fails
- Graceful handling of malformed payloads
- Comprehensive logging for debugging

## 🏗️ Architecture

### Core Components

#### 1. **NavigationService** (`lib/services/navigation_service.dart`)
- Centralized navigation management
- Handles deep linking logic
- Manages pending navigation for unauthenticated users
- Provides fallback navigation

#### 2. **Enhanced PushNotificationService** (`lib/services/push_notification_service.dart`)
- Updated notification tap handler
- Authentication checking
- Integration with NavigationService

#### 3. **Enhanced NotificationService** (`lib/services/notification_service.dart`)
- Creates structured JSON payloads
- Includes notification type and routing data
- Maintains backward compatibility

#### 4. **Updated Main App** (`lib/main.dart`)
- Global navigation key management
- Pending navigation execution after authentication
- Route definitions

## 📱 How It Works

### 1. **Notification Creation**
When a notification is created, the system generates a structured JSON payload:

```json
{
  "type": "order",
  "data": {
    "order_id": "12345"
  },
  "title": "Order Confirmed",
  "message": "Your order has been confirmed",
  "timestamp": "2025-05-30T00:46:44.940877"
}
```

### 2. **Notification Tap Handling**
1. User taps notification
2. `PushNotificationService._onNotificationTapped()` is called
3. Check if user is authenticated
4. If authenticated → Call `NavigationService.handleNotificationTap()`
5. If not authenticated → Set pending navigation

### 3. **Navigation Routing**
1. Parse JSON payload
2. Extract notification type
3. Route to appropriate screen based on type:
   - `appointment` → `AppointmentListScreen`
   - `order` → `PurchaseHistoryPage`
   - `pet` → `AllPetsPage`
   - `promotional` → `DashboardShopScreen`
   - `system` or unknown → `NotificationsListPage`

### 4. **Authentication Flow**
1. If user not logged in → Store pending navigation
2. User completes authentication
3. `AuthWrapper` detects login and calls `_executePendingNavigation()`
4. Navigate to intended destination

## 🔧 Implementation Details

### Navigation Service Methods

```dart
// Main navigation handler
Future<void> handleNotificationTap(String? payload)

// Type-specific handlers
Future<void> _handleAppointmentNotification(Map<String, dynamic> data)
Future<void> _handleOrderNotification(Map<String, dynamic> data)
Future<void> _handlePetNotification(Map<String, dynamic> data)
Future<void> _handlePromotionalNotification(Map<String, dynamic> data)

// Pending navigation management
void setPendingNavigation(String route, [Map<String, dynamic>? data])
Future<void> executePendingNavigation()
```

### Notification Payload Structure

All notifications now include:
- `type`: Notification category for routing
- `data`: Additional context data (IDs, etc.)
- `title`: Display title
- `message`: Display message
- `timestamp`: Creation timestamp

### Error Handling

- Invalid JSON → Navigate to notifications page
- Unknown notification type → Navigate to notifications page
- Navigation failure → Log error and fallback to notifications page
- Missing context → Log error and return gracefully

## 🧪 Testing

### Test Scenarios Verified

1. **✅ Order Notification Deep Linking**
   - Created order notification
   - Tapped notification
   - Successfully navigated to Purchase History page

2. **✅ Appointment Notification Deep Linking**
   - Created appointment notification
   - Tapped notification
   - Successfully navigated to Appointment List page

3. **✅ Authentication Flow**
   - App handles both authenticated and unauthenticated states
   - Pending navigation works correctly

4. **✅ JSON Payload Parsing**
   - Structured payloads are correctly parsed
   - Type-based routing works as expected

### Test Results from Logs

```
I/flutter: PushNotificationService: Notification tapped: {"type":"order","data":{"order_id":"70c401d1-97af-4af2-a399-a7dbe7167836"},...}
I/flutter: NavigationService: Handling notification tap for type: order
I/flutter: NavigationService: Navigated to purchase history

I/flutter: PushNotificationService: Notification tapped: {"type":"appointment","data":{"appointment_id":"cf61a826-ea8c-43a6-b34c-d950ecbdf303"},...}
I/flutter: NavigationService: Handling notification tap for type: appointment
I/flutter: NavigationService: Navigated to appointment list
```

## 🚀 Usage Examples

### Creating Notifications with Deep Linking

```dart
// Order notification
await NotificationService().createOrderNotification(
  title: 'Order Confirmed',
  message: 'Your order has been confirmed',
  orderId: 'order_123',
);

// Appointment notification
await NotificationService().createAppointmentNotification(
  title: 'Appointment Confirmed',
  message: 'Your appointment has been confirmed',
  appointmentId: 'appointment_456',
);
```

### Manual Navigation

```dart
// Navigate to notifications page
await NavigationService().navigateToNotifications();

// Handle custom payload
await NavigationService().handleNotificationTap(customPayload);
```

## 🔮 Future Enhancements

1. **Specific Item Navigation**
   - Navigate directly to order details
   - Navigate to specific appointment details
   - Navigate to specific pet profile

2. **Custom Actions**
   - Quick actions from notifications
   - Inline responses
   - Batch operations

3. **Analytics Integration**
   - Track notification engagement
   - Deep link performance metrics
   - User behavior analysis

## 📝 Notes

- The system maintains backward compatibility with existing notifications
- All navigation is logged for debugging purposes
- The implementation follows Flutter best practices for navigation
- Error handling ensures the app never crashes from notification taps
