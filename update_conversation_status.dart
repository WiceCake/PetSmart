import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jgqxknwrcxxhwylnrpfr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpncXhrbndyY3h4aHd5bG5ycGZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI3MjE5NzQsImV4cCI6MjA0ODI5Nzk3NH0.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8',
  );

  final supabase = Supabase.instance.client;

  try {
    // Update conversation status to resolved
    final response = await supabase
        .from('conversations')
        .update({
          'status': 'resolved',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 'fed77938-e2cb-418b-8f67-9933c3dab0cb');

    debugPrint('Conversation status updated to resolved: $response');
  } catch (e) {
    debugPrint('Error updating conversation status: $e');
  }
}
