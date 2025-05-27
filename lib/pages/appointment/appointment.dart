import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_smart/pages/appointment/calendar.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63); // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373); // Light coral red
const Color accentRed = Color(0xFFEF5350); // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

// Enhanced service card colors for better visual appeal
const Color groomingCardColor = Color(0xFFE3F2FD);    // Light blue for grooming
const Color medicalCardColor = Color(0xFFFFF3E0);     // Light orange for medical
const Color wellnessCardColor = Color(0xFFE8F5E8);    // Light green for wellness

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final List<String> carouselImages = [
    'assets/groom1.jpg',
    'assets/groom2.jpg',
    'assets/groom3.jpg',
  ];

  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % carouselImages.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white, Colors.grey[50]!],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              _buildAppBar(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome banner
                      _buildWelcomeBanner(),
                      const SizedBox(height: 28),
                // Carousel Images
                SizedBox(
                  height: 170,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: carouselImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            carouselImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      );
                    },
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Carousel indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    carouselImages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == index
                                ? primaryBlue
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Section: Grooming Packages
                _SectionHeader(
                  title: "GROOMING PACKAGES",
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withValues(alpha: 0.1),
                      primaryBlue.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                _ServiceCard(
                  color: groomingCardColor,
                  icon: Icons.cut,
                  iconColor: const Color(0xFF1976D2),
                  title: "Full Grooming – Small Breed",
                  subtitle: "(below 10 kg)",
                  price: "₱600",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booked Full Grooming – Small Breed!'),
                      ),
                    );
                  },
                ),
                _ServiceCard(
                  color: groomingCardColor,
                  icon: Icons.cut,
                  iconColor: const Color(0xFF1976D2),
                  title: "Full Grooming – Medium Breed",
                  subtitle: "(11kg to 20kg)",
                  price: "₱800",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booked Full Grooming – Medium Breed!'),
                      ),
                    );
                  },
                ),
                _ServiceCard(
                  color: groomingCardColor,
                  icon: Icons.cut,
                  iconColor: const Color(0xFF1976D2),
                  title: "Full Grooming – Large Breed",
                  subtitle: "(21kg to 30kg)",
                  price: "₱1000",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booked Full Grooming – Large Breed!'),
                      ),
                    );
                  },
                ),
                _ServiceCard(
                  color: groomingCardColor,
                  icon: Icons.bubble_chart,
                  iconColor: const Color(0xFF1976D2),
                  title: "Bath & Blowdry – Small Breed",
                  subtitle: "(below 10 kg)",
                  price: "₱300",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booked Bath & Blowdry – Small Breed!'),
                      ),
                    );
                  },
                ),
                _ServiceCard(
                  color: groomingCardColor,
                  icon: Icons.medical_services,
                  iconColor: const Color(0xFF1976D2),
                  title: "Teeth Brushing",
                  price: "₱100",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booked Teeth Brushing!')),
                    );
                  },
                ),
                _ServiceCard(
                  color: groomingCardColor,
                  icon: Icons.cleaning_services,
                  iconColor: const Color(0xFF1976D2),
                  title: "Ear Cleaning",
                  price: "₱100",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booked Ear Cleaning!')),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Section: Vaccine & Pharmacy
                _SectionHeader(
                  title: "VACCINE & PHARMACY",
                  gradient: LinearGradient(
                    colors: [
                      primaryRed.withValues(alpha: 0.1),
                      primaryRed.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                _ServiceCard(
                  color: medicalCardColor,
                  icon: Icons.medical_services,
                  iconColor: const Color(0xFFFF9800),
                  title: "Deworming 5kg below Tablet",
                  price: "₱160",
                ),
                _ServiceCard(
                  color: medicalCardColor,
                  icon: Icons.medical_services,
                  iconColor: const Color(0xFFFF9800),
                  title: "Deworming 6kg to 10kg",
                  price: "₱300",
                ),
                _ServiceCard(
                  color: medicalCardColor,
                  icon: Icons.medical_services,
                  iconColor: const Color(0xFFFF9800),
                  title: "Deworming 11kg to 20kg Tablet",
                  price: "₱400",
                ),
                _ServiceCard(
                  color: medicalCardColor,
                  icon: Icons.vaccines,
                  iconColor: const Color(0xFFFF9800),
                  title: "Tricat Vaccine",
                  price: "₱1,200",
                ),
                _ServiceCard(
                  color: medicalCardColor,
                  icon: Icons.vaccines,
                  iconColor: const Color(0xFFFF9800),
                  title: "Vaccine 6-in-1",
                  price: "₱950",
                ),
                _ServiceCard(
                  color: medicalCardColor,
                  icon: Icons.vaccines,
                  iconColor: const Color(0xFFFF9800),
                  title: "Vaccine 8-in-1",
                  price: "₱750",
                ),
                const SizedBox(height: 24),
                // Section: Wellness & Laboratory
                _SectionHeader(
                  title: "WELLNESS & LABORATORY",
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withValues(alpha: 0.1),
                      primaryBlue.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                _ServiceCard(
                  color: wellnessCardColor,
                  icon: Icons.assignment_turned_in,
                  iconColor: const Color(0xFF4CAF50),
                  title: "Issuance of Health Certificate",
                  price: "₱400",
                ),
                _ServiceCard(
                  color: wellnessCardColor,
                  icon: Icons.health_and_safety,
                  iconColor: const Color(0xFF4CAF50),
                  title: "General Health Profile",
                  price: "₱2,500",
                ),
                _ServiceCard(
                  color: wellnessCardColor,
                  icon: Icons.cleaning_services,
                  iconColor: const Color(0xFF4CAF50),
                  title: "Professional Dental Cleaning 10kg below",
                  price: "₱3,000",
                ),
                _ServiceCard(
                  color: wellnessCardColor,
                  icon: Icons.medical_information,
                  iconColor: const Color(0xFF4CAF50),
                  title: "Digital X-ray",
                  price: "₱1,000",
                ),
                _ServiceCard(
                  color: wellnessCardColor,
                  icon: Icons.bug_report,
                  iconColor: const Color(0xFF4CAF50),
                  title: "Heartworm Antigen Test Kit",
                  price: "₱1,000",
                ),
                _ServiceCard(
                  color: wellnessCardColor,
                  icon: Icons.local_hospital,
                  iconColor: const Color(0xFF4CAF50),
                  title: "Consultation Fee",
                  price: "₱500",
                ),
                const SizedBox(height: 24),
                // Section: Pet Insurance (improved)
                Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          backgroundColor,
                          primaryBlue.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: primaryBlue,
                              child: Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "What is Pet Insurance?",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: primaryBlue,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Pet insurance provides medical reimbursement for covered accidental injuries, plus accident insurance for the pet owner. Depending on your and your pet’s lifestyles and your budget, you can choose to add any following benefits:",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            decoration: TextDecoration.none,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _FeatureChip(label: "Medical Reimbursement"),
                            _FeatureChip(label: "Owner’s Liability"),
                            _FeatureChip(label: "Dental Conditions"),
                            _FeatureChip(label: "Accidental Death/Euthanasia"),
                            _FeatureChip(label: "Pethap Benefits"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today, size: 24),
                      label: const Text("Schedule an Appointment"),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => const AppointmentCalendarPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryBlue),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/petsmart_word.png',
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 50,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pets,
                      size: 24,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, secondaryBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Complete Care\nfor Your Pets",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Professional grooming, medical care, and wellness services",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Gradient gradient;

  const _SectionHeader({required this.title, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 2,
          color: primaryBlue,
        ),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String price;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.color,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.price,
    this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: Card(
        elevation: 4,
        shadowColor: widget.color.withValues(alpha: 0.3),
        color: widget.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          // Make the card clickable for animation only, no action
          onTap: () {},
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.iconColor ?? primaryBlue).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor ?? primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  widget.price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, color: primaryBlue),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}
