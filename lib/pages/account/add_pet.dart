import 'package:flutter/material.dart';
import 'package:pet_smart/auth/auth.dart';

class AddPetAccountScreen extends StatefulWidget {
  final String? userName;
  const AddPetAccountScreen({super.key, this.userName});

  @override
  State<AddPetAccountScreen> createState() => _AddPetAccountScreenState();
}

class _AddPetAccountScreenState extends State<AddPetAccountScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController petNameController = TextEditingController();
  String? selectedPetType;
  String? selectedGender;

  final List<String> petTypes = ['Dog', 'Cat', 'Bird', 'Fish', 'Other'];
  final List<String> genders = ['Male', 'Female'];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    petNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF233A63);
    const accentColor = Color(0xFFE57373);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          },
        ),
        title: const Text(
          "Add a Pet",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pet Avatar/Icon
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(18),
                        child: const Icon(
                          Icons.pets,
                          color: Color(0xFF233A63),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Pet Information",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Fill in the details below to add your pet.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      const SizedBox(height: 28),
                      // Pet Name Field
                      _AnimatedInputField(
                        controller: petNameController,
                        hintText: 'Pet Name',
                        icon: Icons.pets,
                      ),
                      const SizedBox(height: 18),
                      // Pet Type Dropdown
                      _AnimatedDropdownField(
                        value: selectedPetType,
                        items: petTypes,
                        hintText: 'Type Of Pet',
                        icon: Icons.category_outlined,
                        onChanged: (value) {
                          setState(() {
                            selectedPetType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      // Gender Dropdown
                      _AnimatedDropdownField(
                        value: selectedGender,
                        items: genders,
                        hintText: 'Gender',
                        icon: Icons.transgender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    setState(() => _isLoading = true);
                                    await Future.delayed(
                                      const Duration(seconds: 1),
                                    );
                                    setState(() => _isLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pet added successfully!',
                                        ),
                                        backgroundColor: accentColor,
                                      ),
                                    );
                                    // Wait a moment for the SnackBar to show, then navigate back
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                    if (mounted) Navigator.pop(context);
                                  },
                          label:
                              _isLoading
                                  ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                  : const Text(
                                    'Add Pet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      letterSpacing: 1,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;

  const _AnimatedInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFF233A63)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}

class _AnimatedDropdownField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hintText;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _AnimatedDropdownField({
    required this.value,
    required this.items,
    required this.hintText,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFF233A63)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        dropdownColor: Colors.white,
      ),
    );
  }
}
