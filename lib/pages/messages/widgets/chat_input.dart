import 'dart:async';
import 'package:flutter/material.dart';

// Enhanced color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);     // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5);   // Secondary blue
const Color backgroundColor = Color(0xFFF8F9FA); // Light background
const Color textSecondary = Color(0xFF666666);   // Secondary text

/// Widget for chat input with text and typing indicator functionality
class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final Function(bool) onTypingChanged;
  final bool isEnabled;
  final String hintText;
  final int maxLength;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onTypingChanged,
    this.isEnabled = true,
    this.hintText = 'Type your message...',
    this.maxLength = 1000,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;

    if (hasText != _showSendButton) {
      setState(() {
        _showSendButton = hasText;
      });
    }

    // Handle typing indicator
    if (hasText && !_isTyping) {
      _isTyping = true;
      widget.onTypingChanged(true);
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged(false);
      }
    });
  }

  void _sendMessage() {
    final text = widget.controller.text.trim();
    debugPrint('ChatInput._sendMessage called with: "$text"');
    debugPrint('ChatInput.isEnabled: ${widget.isEnabled}');

    if (text.isEmpty || !widget.isEnabled) {
      debugPrint('ChatInput: Message empty or disabled, returning');
      return;
    }

    if (text.length > widget.maxLength) {
      debugPrint('ChatInput: Message too long, showing error');
      _showLengthError();
      return;
    }

    debugPrint('ChatInput: Calling onSendMessage callback');
    widget.onSendMessage(text);
    widget.controller.clear();

    // Stop typing indicator
    if (_isTyping) {
      _isTyping = false;
      widget.onTypingChanged(false);
    }
  }

  void _showLengthError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message too long (max ${widget.maxLength} characters)'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    enabled: widget.isEnabled,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: widget.maxLength,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      counterText: '', // Hide character counter
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showSendButton
                    ? IconButton(
                        onPressed: widget.isEnabled ? _sendMessage : null,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: widget.isEnabled ? primaryBlue : textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                      )
                    : const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
