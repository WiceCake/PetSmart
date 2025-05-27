import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  String _result = 'Press the button to test Supabase connection.';

  Future<void> _testConnection() async {
    try {
      final response = await Supabase.instance.client
          .from('products') // Replace with your table name
          .select()
          .limit(1)
          .maybeSingle();
      setState(() {
        _result = response != null
            ? 'Success: \\n$response'
            : 'No data found or wrong table name.';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(_result, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('Test Supabase Connection'),
            ),
          ],
        ),
      ),
    );
  }
} 