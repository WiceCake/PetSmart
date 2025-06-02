import 'package:flutter/material.dart';
import 'package:pet_smart/services/chat_service.dart';
import 'package:pet_smart/pages/messages/direct_chat_admin.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color textPrimary = Color(0xFF1A1A1A);   // Primary text
const Color textSecondary = Color(0xFF666666); // Secondary text

/// New Conversation screen for entering conversation subject
class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key});

  @override
  State<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<NewConversationPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _subjectController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCreating = false;

  // Predefined subject suggestions
  final List<String> _subjectSuggestions = [
    'General Support',
    'Account Issues',
    'Pet Care Questions',
    'Appointment Booking',
    'Product Information',
    'Billing & Payments',
    'Technical Support',
    'Feedback & Suggestions',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _chatService.dispose(); // Properly dispose ChatService
    super.dispose();
  }

  Future<void> _createConversation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final subject = _subjectController.text.trim();
    
    try {
      setState(() => _isCreating = true);

      final conversation = await _chatService.createConversation(subject);
      
      if (conversation != null && mounted) {
        // Navigate to the chat screen with the new conversation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DirectChatAdminPage(
              conversationId: conversation.id,
            ),
          ),
        );

        EnhancedToasts.showSuccess(
          context,
          'Conversation started successfully! 💬',
        );
      } else {
        if (mounted) {
          EnhancedToasts.showError(
            context,
            'Failed to create conversation. Please try again.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Failed to create conversation. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    _subjectController.text = suggestion;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'New Conversation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.support_agent_rounded,
                            color: primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start a Support Conversation',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Our support team is here to help!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Subject input section
              const Text(
                'What can we help you with?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide a brief subject for your inquiry. This helps our support team assist you better.',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Subject input field
              TextFormField(
                controller: _subjectController,
                enabled: !_isCreating,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g., General Support, Account Issues...',
                  prefixIcon: Icon(
                    Icons.subject_rounded,
                    color: primaryBlue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryBlue, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject for your conversation';
                  }
                  if (value.trim().length < 3) {
                    return 'Subject must be at least 3 characters long';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _createConversation(),
              ),

              const SizedBox(height: 24),

              // Quick suggestions
              const Text(
                'Quick Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjectSuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: _isCreating ? null : () => _selectSuggestion(suggestion),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[300]!),
                    labelStyle: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Create conversation button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start Conversation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryBlue.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Our support team typically responds within a few hours during business hours.',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryBlue,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
