-- PetSmart Notification System Database Setup
-- Run this SQL in your Supabase SQL Editor

-- ============================================================================
-- CHAT SYSTEM DATABASE SETUP
-- ============================================================================

-- 1. Enhance existing messages table for comprehensive chat functionality
-- First, add missing columns to the existing messages table
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS conversation_id UUID,
ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
ADD COLUMN IF NOT EXISTS read_status BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS attachment_url TEXT,
ADD COLUMN IF NOT EXISTS is_from_user BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Update sent_at to use timezone
ALTER TABLE messages ALTER COLUMN sent_at TYPE TIMESTAMP WITH TIME ZONE;
ALTER TABLE messages ALTER COLUMN sent_at SET DEFAULT NOW();

-- 2. Create conversations table for better organization
CREATE TABLE IF NOT EXISTS conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'archived')),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    unread_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Add foreign key constraint for conversation_id in messages
ALTER TABLE messages
ADD CONSTRAINT fk_messages_conversation
FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;

-- 4. Create typing_indicators table for real-time typing status
CREATE TABLE IF NOT EXISTS typing_indicators (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    last_typed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_read_status ON messages(read_status);
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_conversation_id ON typing_indicators(conversation_id);

-- 6. Enable Row Level Security (RLS) for new tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for conversations
CREATE POLICY "Users can view their own conversations" ON conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create conversations" ON conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations" ON conversations
    FOR UPDATE USING (auth.uid() = user_id);

-- 8. Create RLS policies for typing_indicators
CREATE POLICY "Users can view typing indicators in their conversations" ON typing_indicators
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = typing_indicators.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage their own typing indicators" ON typing_indicators
    FOR ALL USING (auth.uid() = user_id);

-- 9. Update existing messages RLS policies to work with conversations
DROP POLICY IF EXISTS "Send/receive own messages" ON messages;
DROP POLICY IF EXISTS "Send messages" ON messages;

CREATE POLICY "Users can view messages in their conversations" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can send messages in their conversations" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- 10. Create functions for automatic conversation management
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET
        last_message_at = NEW.created_at,
        updated_at = NOW(),
        unread_count = CASE
            WHEN NEW.is_from_user = FALSE THEN unread_count + 1
            ELSE unread_count
        END
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_conversation_if_not_exists()
RETURNS TRIGGER AS $$
BEGIN
    -- If no conversation_id is provided, create a new conversation
    IF NEW.conversation_id IS NULL THEN
        INSERT INTO conversations (user_id, last_message_at)
        VALUES (NEW.sender_id, NEW.created_at)
        RETURNING id INTO NEW.conversation_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. Create triggers
CREATE TRIGGER trigger_update_conversation_last_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

CREATE TRIGGER trigger_create_conversation_if_not_exists
    BEFORE INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION create_conversation_if_not_exists();

-- 12. Create function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(conversation_uuid UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE messages
    SET read_status = TRUE
    WHERE conversation_id = conversation_uuid
    AND is_from_user = FALSE
    AND read_status = FALSE;

    UPDATE conversations
    SET unread_count = 0
    WHERE id = conversation_uuid;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- NOTIFICATION SYSTEM (EXISTING)
-- ============================================================================

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('appointment', 'order', 'pet', 'promotional', 'system')),
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- 2. Create notification_preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('appointment', 'order', 'pet', 'promotional', 'system')),
    push_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT TRUE,
    in_app_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, type)
);

-- 3. Push tokens table removed - using local notifications only

-- 4. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON notification_preferences(user_id);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for notifications table
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notifications" ON notifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- 7. Create RLS policies for notification_preferences table
CREATE POLICY "Users can view own notification preferences" ON notification_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification preferences" ON notification_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification preferences" ON notification_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notification preferences" ON notification_preferences
    FOR DELETE USING (auth.uid() = user_id);

-- 8. Push tokens policies removed - using local notifications only

-- 9. Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 10. Create triggers for updated_at columns
CREATE TRIGGER update_notification_preferences_updated_at
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 11. Create function to initialize default notification preferences for new users
CREATE OR REPLACE FUNCTION initialize_user_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notification_preferences (user_id, type, push_enabled, email_enabled, in_app_enabled)
    VALUES
        (NEW.id, 'appointment', TRUE, TRUE, TRUE),
        (NEW.id, 'order', TRUE, TRUE, TRUE),
        (NEW.id, 'pet', TRUE, FALSE, TRUE),
        (NEW.id, 'promotional', FALSE, FALSE, TRUE),
        (NEW.id, 'system', TRUE, FALSE, TRUE);
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 12. Create trigger to initialize preferences when a new user signs up
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION initialize_user_notification_preferences();

-- 13. Insert some sample data for testing (optional)
-- You can uncomment these lines to add test notifications
/*
INSERT INTO notifications (user_id, title, message, type, data) VALUES
    ((SELECT id FROM auth.users LIMIT 1), 'Welcome to PetSmart!', 'Thank you for joining our app. Explore all the features to take care of your pets.', 'system', '{"welcome": true}'),
    ((SELECT id FROM auth.users LIMIT 1), 'Appointment Reminder', 'Your pet appointment is scheduled for tomorrow at 2:00 PM.', 'appointment', '{"appointment_id": "123"}'),
    ((SELECT id FROM auth.users LIMIT 1), 'Order Confirmed', 'Your order #12345 has been confirmed and will be delivered soon.', 'order', '{"order_id": "12345"}');
*/
