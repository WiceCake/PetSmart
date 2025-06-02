import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountInformationPage extends StatefulWidget {
  const AccountInformationPage({super.key});

  @override
  State<AccountInformationPage> createState() => _AccountInformationPageState();
}

class _AccountInformationPageState extends State<AccountInformationPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _userData = {};
  bool _isEditing = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      // Fetch user profile data
      final response = await supabase
          .from('profiles')
          .select('first_name, last_name, phone_number, birthdate, profile_pic, username, bio')
          .eq('id', user.id)
          .single();

      setState(() {
        _userData = {
          'name': '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim(),
          'firstName': response['first_name'] ?? '',
          'lastName': response['last_name'] ?? '',
          'email': user.email ?? '',
          'phone': response['phone_number'] ?? '',
          'birthDate': response['birthdate'] ?? '',
          'profilePic': response['profile_pic'],
          'username': response['username'] ?? '',
          'bio': response['bio'] ?? '',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load user data: ${e.toString()}';
        // Set default values if loading fails
        _userData = {
          'name': 'User',
          'firstName': '',
          'lastName': '',
          'email': '',
          'phone': '',
          'birthDate': '',
          'profilePic': null,
          'username': '',
          'bio': '',
        };
      });
    }
  }

  Future<void> _updateUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      // Update user profile data
      await supabase.from('profiles').update({
        'first_name': _userData['firstName'],
        'last_name': _userData['lastName'],
        'phone_number': _userData['phone'],
        'birthdate': _userData['birthDate'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      _showSuccessAnimation();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to update profile: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF233A63);   // PetSmart brand blue
    const backgroundColor = Color(0xFFF8F9FA);
    const cardColor = Colors.white;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        centerTitle: true,
        title: const Text(
          'Account Information',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: primaryBlue.withValues(alpha: 0.1),
              child: ClipOval(
                child: _userData['profilePic'] != null
                    ? Image.network(
                        _userData['profilePic'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, size: 44, color: primaryBlue);
                        },
                      )
                    : Icon(Icons.person, size: 44, color: primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              _userData['name'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
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
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Personal Details',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (_isEditing) {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              await _updateUserData();
                            }
                          } else {
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: primaryBlue,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
                      children: _buildFormFields(primaryBlue),
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

  List<Widget> _buildFormFields(Color primaryBlue) {
    final List<Map<String, dynamic>> fields = [
      {
        'label': 'First Name',
        'icon': Icons.person_outline,
        'initialValue': _userData['firstName'] ?? '',
        'key': 'firstName',
        'keyboardType': TextInputType.name,
        'validator': (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your first name';
          }
          return null;
        },
      },
      {
        'label': 'Last Name',
        'icon': Icons.person_outline,
        'initialValue': _userData['lastName'] ?? '',
        'key': 'lastName',
        'keyboardType': TextInputType.name,
        'validator': (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your last name';
          }
          return null;
        },
      },
      {
        'label': 'Email Address',
        'icon': Icons.email_outlined,
        'initialValue': _userData['email'] ?? '',
        'key': 'email',
        'readOnly': true, // Email should not be editable
        'keyboardType': TextInputType.emailAddress,
        'validator': (value) {
          // Skip validation for read-only email field
          return null;
        },
      },
      {
        'label': 'Phone Number',
        'icon': Icons.phone_outlined,
        'initialValue': _userData['phone'] ?? '',
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
        'initialValue': _userData['birthDate'] ?? '',
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
          isEditing: _isEditing && (field['readOnly'] != true),
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
                      primary: primaryBlue,
                      onPrimary: Colors.white,
                    ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
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
          primaryBlue: primaryBlue,
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
    required Color primaryBlue,
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
        prefixIcon: Icon(icon, color: primaryBlue, size: 22),
        labelText: label,
        labelStyle: TextStyle(
          color: primaryBlue.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: isEditing && onTap != null
            ? Icon(Icons.arrow_drop_down, color: primaryBlue)
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
                color: Colors.black.withValues(alpha: 0.1),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
