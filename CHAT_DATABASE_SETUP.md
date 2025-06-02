# Chat System Database Setup

## 🚨 IMPORTANT: Database Setup Required

The chat system is currently running in **fallback mode** using the basic `messages` table. To enable full chat functionality with conversations, real-time features, and enhanced capabilities, you need to run the database setup.

## Current Status

✅ **Working Now (Fallback Mode):**
- ✅ Send text messages
- ✅ Basic message history
- ✅ Chat input functionality
- ✅ Image attachments (basic)

🔄 **Available After Database Setup:**
- 🔄 Conversation management
- 🔄 Real-time messaging
- 🔄 Typing indicators
- 🔄 Message read status
- 🔄 Unread message counts
- 🔄 Enhanced message features

## Quick Setup Instructions

### Step 1: Run Database Script
1. Open your **Supabase Dashboard**
2. Go to **SQL Editor**
3. Copy and paste the contents of `database_setup.sql`
4. Click **Run** to execute the script

### Step 2: Create Storage Bucket
Run this in the Supabase SQL Editor:

```sql
-- Create storage bucket for chat attachments
INSERT INTO storage.buckets (id, name, public) 
VALUES ('chat_attachments', 'chat_attachments', true);

-- Create storage policies
CREATE POLICY "Users can upload chat attachments" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'chat_attachments' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view chat attachments" ON storage.objects
FOR SELECT USING (bucket_id = 'chat_attachments');
```

### Step 3: Restart the App
After running the database setup:
1. Stop the Flutter app (`q` in terminal)
2. Run `flutter clean`
3. Run `flutter run` again

## Verification

After setup, you should see these debug messages:
```
ChatService: Found existing conversation: [conversation-id]
ChatService: Message sent successfully with enhanced schema: [message-id]
```

Instead of:
```
ChatService: Conversations table not available, using fallback
ChatService: Message sent successfully with basic schema: [message-id]
```

## Troubleshooting

### If Chat Input Still Not Working:
1. Check terminal for error messages
2. Verify user is logged in
3. Check Supabase connection
4. Try hot restart (`R` in terminal)

### If Database Setup Fails:
1. Check Supabase project permissions
2. Verify you're in the correct project
3. Check for existing table conflicts
4. Contact support if issues persist

## Features After Setup

Once the database is properly set up, you'll have access to:

### 🔄 Real-time Messaging
- Messages appear instantly without refresh
- Live typing indicators
- Real-time message status updates

### 💬 Conversation Management
- Organized chat sessions
- Conversation history
- Multiple conversation support

### 📊 Enhanced Features
- Message read receipts
- Unread message counts
- Message search functionality
- File attachment support

### 🔔 Push Notifications
- New message notifications
- Deep linking to conversations
- Background message alerts

## Current Fallback Behavior

The chat system is designed to work even without the enhanced database schema:

- **Messages**: Stored in basic `messages` table
- **Conversations**: Virtual conversation IDs
- **Real-time**: Disabled gracefully
- **Features**: Basic functionality maintained

This ensures the chat system is always functional while you set up the enhanced features.

## Need Help?

If you encounter any issues:

1. **Check the terminal output** for specific error messages
2. **Verify database setup** by checking if tables exist in Supabase
3. **Test basic functionality** first (sending simple text messages)
4. **Review the debug logs** for detailed troubleshooting information

The chat system includes comprehensive debugging to help identify and resolve any issues quickly.
