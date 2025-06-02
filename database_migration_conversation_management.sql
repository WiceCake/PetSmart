-- Database Migration for Conversation Management System
-- This script updates the conversations table to support the new chat history and conversation management features

-- Add new columns to conversations table
ALTER TABLE conversations 
ADD COLUMN IF NOT EXISTS subject TEXT,
ADD COLUMN IF NOT EXISTS last_message TEXT;

-- Update existing conversations to have default subjects
UPDATE conversations 
SET subject = 'Customer Support' 
WHERE subject IS NULL OR subject = '';

-- Update status values to use new system
-- Convert old status values to new ones
UPDATE conversations 
SET status = 'active' 
WHERE status = 'pending';

UPDATE conversations 
SET status = 'completed' 
WHERE status = 'resolved';

-- Create index for better performance on user conversations
CREATE INDEX IF NOT EXISTS idx_conversations_user_status 
ON conversations(user_id, status);

CREATE INDEX IF NOT EXISTS idx_conversations_user_last_message 
ON conversations(user_id, last_message_at DESC);

-- Create a function to update last_message when messages are inserted
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the conversation's last_message and last_message_at
    UPDATE conversations 
    SET 
        last_message = NEW.message_content,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update last_message
DROP TRIGGER IF EXISTS trigger_update_conversation_last_message ON messages;
CREATE TRIGGER trigger_update_conversation_last_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Update existing conversations with their last message
UPDATE conversations 
SET last_message = (
    SELECT message_content 
    FROM messages 
    WHERE messages.conversation_id = conversations.id 
    ORDER BY created_at DESC 
    LIMIT 1
)
WHERE last_message IS NULL;

-- Ensure all conversations have proper timestamps
UPDATE conversations 
SET last_message_at = updated_at 
WHERE last_message_at IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN conversations.subject IS 'The subject/title of the conversation provided by the user';
COMMENT ON COLUMN conversations.last_message IS 'The content of the last message in the conversation for preview';
COMMENT ON COLUMN conversations.status IS 'Conversation status: active, completed, closed, archived';

-- Create a view for conversation summaries (optional, for admin dashboard)
CREATE OR REPLACE VIEW conversation_summaries AS
SELECT 
    c.id,
    c.user_id,
    c.subject,
    c.status,
    c.last_message,
    c.last_message_at,
    c.unread_count,
    c.created_at,
    c.updated_at,
    COUNT(m.id) as total_messages,
    u.email as user_email
FROM conversations c
LEFT JOIN messages m ON c.id = m.conversation_id
LEFT JOIN auth.users u ON c.user_id = u.id
GROUP BY c.id, u.email
ORDER BY c.last_message_at DESC;

-- Grant necessary permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE ON conversations TO authenticated;
-- GRANT SELECT ON conversation_summaries TO authenticated;

-- Sample data for testing (remove in production)
-- INSERT INTO conversations (user_id, subject, status, unread_count, last_message_at) 
-- VALUES 
--     ('sample-user-id', 'General Support', 'active', 0, NOW()),
--     ('sample-user-id', 'Account Issues', 'completed', 0, NOW() - INTERVAL '1 day'),
--     ('sample-user-id', 'Pet Care Questions', 'active', 2, NOW() - INTERVAL '2 hours');

-- Verification queries (run these to check the migration)
-- SELECT COUNT(*) as total_conversations FROM conversations;
-- SELECT status, COUNT(*) as count FROM conversations GROUP BY status;
-- SELECT * FROM conversations WHERE subject IS NULL OR subject = '';
-- SELECT * FROM conversation_summaries LIMIT 5;

COMMIT;
