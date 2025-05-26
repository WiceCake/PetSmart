import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class AccountInformationPage extends StatefulWidget {
  const AccountInformationPage({super.key});

  @override
  State<AccountInformationPage> createState() => _AccountInformationPageState();
}

class _AccountInformationPageState extends State<AccountInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _userData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'phone': '+63 9123456789',
    'birthDate': '1990-01-01',
  };
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF3B4CCA);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Account',
          style: TextStyle(
            color: mainBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: mainBlue),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFFE8EAF6),
              child: ClipOval(
                child: Image.asset(
                  'assets/profile_placeholder.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 44, color: mainBlue);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              _userData['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainBlue,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _userData['email'],
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 16),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(
                          color: mainBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_isEditing) {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              _showSuccessAnimation();
                            }
                          }
                          setState(() {
                            _isEditing = !_isEditing;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: mainBlue,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        child: Text(_isEditing ? 'Save' : 'Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFormFields(mainBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields(Color mainBlue) {
    final List<Map<String, dynamic>> fields = [
      {
        'label': 'Full Name',
        'icon': Icons.person_outline,
        'initialValue': _userData['name'],
        'key': 'name',
        'keyboardType': TextInputType.name,
        'validator': (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your name';
          }
          return null;
        },
      },
      {
        'label': 'Email Address',
        'icon': Icons.email_outlined,
        'initialValue': _userData['email'],
        'key': 'email',
        'keyboardType': TextInputType.emailAddress,
        'validator': (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          return null;
        },
      },
      {
        'label': 'Phone Number',
        'icon': Icons.phone_outlined,
        'initialValue': _userData['phone'],
        'key': 'phone',
        'keyboardType': TextInputType.phone,
        'validator': (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          return null;
        },
      },
      {
        'label': 'Birth Date',
        'icon': Icons.calendar_today_outlined,
        'initialValue': _userData['birthDate'],
        'key': 'birthDate',
        'isDate': true,
        'validator': (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your birth date';
          }
          return null;
        },
      },
    ];

    List<Widget> formWidgets = [];
    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      formWidgets.add(
        _buildFormField(
          label: field['label'],
          initialValue: field['initialValue'],
          icon: field['icon'],
          isEditing: _isEditing,
          keyboardType: field['keyboardType'] ?? TextInputType.text,
          validator: field['validator'],
          onSaved: (value) {
            _userData[field['key']] = value;
          },
          onTap: field['isDate'] == true && _isEditing ? () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(
                      primary: mainBlue,
                      onPrimary: Colors.white,
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _userData['birthDate'] = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              });
            }
          } : null,
          mainBlue: mainBlue,
        ),
      );
      if (i < fields.length - 1) {
        formWidgets.add(const SizedBox(height: 16));
      }
    }
    return formWidgets;
  }

  Widget _buildFormField({
    required String label,
    required String initialValue,
    required IconData icon,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function()? onTap,
    required Color mainBlue,
  }) {
    return TextFormField(
      initialValue: initialValue,
      enabled: isEditing,
      readOnly: onTap != null,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF222222),
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: mainBlue, size: 22),
        labelText: label,
        labelStyle: TextStyle(
          color: mainBlue.withOpacity(0.8),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mainBlue.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mainBlue.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mainBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: isEditing && onTap != null
            ? Icon(Icons.arrow_drop_down, color: mainBlue)
            : null,
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      onTap: onTap,
      textInputAction: TextInputAction.next,
    );
  }

  void _showSuccessAnimation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade800,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Profile updated successfully',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100, top: 16),
      ),
    );
  }
}
