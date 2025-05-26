import 'package:flutter/material.dart';

class CountryPage extends StatefulWidget {
  const CountryPage({super.key});

  @override
  State<CountryPage> createState() => _CountryPageState();
}

class _CountryPageState extends State<CountryPage> {
  final Map<String, dynamic> _philippines = {'name': 'Philippines', 'code': 'PH', 'flag': '🇵🇭'};
  String _selectedCountryCode = 'PH';

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF3B4CCA);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Select Country',
          style: TextStyle(
            color: mainBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: mainBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE8EAF6),
                child: Text(_philippines['flag'], style: const TextStyle(fontSize: 22), semanticsLabel: 'Philippines flag'),
              ),
              title: Text(
                _philippines['name'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Country code: ${_philippines['code']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: mainBlue,
                size: 22,
              ),
              onTap: () {
                Navigator.pop(context, _philippines);
              },
            ),
          ),
        ],
      ),
    );
  }
}