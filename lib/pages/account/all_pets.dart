import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pet_details.dart';
import 'add_pet.dart';
import 'package:pet_smart/components/skeleton_screens.dart';
import 'package:pet_smart/services/lazy_loading_service.dart';

// Enhanced color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);     // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5);   // Secondary blue
const Color backgroundColor = Color(0xFFF8F9FA); // Light background
const Color cardColor = Colors.white;            // Card background
const Color successGreen = Color(0xFF4CAF50);    // Success green
const Color textPrimary = Color(0xFF222222);     // Primary text
const Color textSecondary = Color(0xFF666666);   // Secondary text

class AllPetsPage extends StatefulWidget {
  final List<Map<String, dynamic>> pets;

  const AllPetsPage({super.key, required this.pets});

  @override
  State<AllPetsPage> createState() => _AllPetsPageState();
}

class _AllPetsPageState extends State<AllPetsPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _filteredPets = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late LazyLoadingService<Map<String, dynamic>> _lazyLoadingService;

  // Filter and sort state
  String _selectedTypeFilter = 'All';
  String _selectedGenderFilter = 'All';
  String _sortBy = 'newest'; // newest, oldest, name
  bool _isFilterExpanded = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize lazy loading service
    _lazyLoadingService = LazyLoadingService<Map<String, dynamic>>(
      loadData: _loadPetsPage,
      pageSize: 20,
    );

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pets = List.from(widget.pets);
    _filteredPets = List.from(_pets);
    _searchController.addListener(_filterAndSortPets);

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Load initial data with skeleton
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _lazyLoadingService.dispose();
    super.dispose();
  }

  /// Load pets page for lazy loading
  Future<List<Map<String, dynamic>>> _loadPetsPage(int page, int limit) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return [];

      final offset = (page - 1) * limit;
      final response = await supabase
          .from('pets')
          .select('id, name, type, gender, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading pets page: $e');
      return [];
    }
  }

  /// Load initial data with skeleton loading
  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
    });

    // Simulate loading delay for skeleton effect
    await Future.delayed(const Duration(milliseconds: 500));

    await _lazyLoadingService.loadInitial();

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _filterAndSortPets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPets = _pets.where((pet) {
        final name = (pet['name'] ?? '').toString().toLowerCase();
        final type = (pet['type'] ?? '').toString().toLowerCase();
        final gender = (pet['gender'] ?? '').toString().toLowerCase();

        // Apply search filter
        bool matchesSearch = query.isEmpty ||
            name.contains(query) ||
            type.contains(query) ||
            gender.contains(query);

        // Apply type filter
        bool matchesType = _selectedTypeFilter == 'All' ||
            (pet['type'] ?? '').toString() == _selectedTypeFilter;

        // Apply gender filter
        bool matchesGender = _selectedGenderFilter == 'All' ||
            (pet['gender'] ?? '').toString() == _selectedGenderFilter;

        return matchesSearch && matchesType && matchesGender;
      }).toList();

      // Apply sorting
      _filteredPets.sort((a, b) {
        switch (_sortBy) {
          case 'name':
            return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
          case 'oldest':
            return DateTime.parse(a['created_at'] ?? '').compareTo(DateTime.parse(b['created_at'] ?? ''));
          case 'newest':
          default:
            return DateTime.parse(b['created_at'] ?? '').compareTo(DateTime.parse(a['created_at'] ?? ''));
        }
      });
    });
  }

  void _updateTypeFilter(String type) {
    setState(() {
      _selectedTypeFilter = type;
    });
    _filterAndSortPets();
  }

  void _updateGenderFilter(String gender) {
    setState(() {
      _selectedGenderFilter = gender;
    });
    _filterAndSortPets();
  }

  void _updateSorting(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _filterAndSortPets();
  }



  void _toggleFilterExpansion() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTypeFilter = 'All';
      _selectedGenderFilter = 'All';
      _sortBy = 'newest';
      _searchController.clear();
    });
    _filterAndSortPets();
  }



  // Check if any filters are active
  bool get _hasActiveFilters {
    return _selectedTypeFilter != 'All' ||
           _selectedGenderFilter != 'All' ||
           _searchController.text.isNotEmpty;
  }

  // Count active filters
  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedTypeFilter != 'All') count++;
    if (_selectedGenderFilter != 'All') count++;
    if (_searchController.text.isNotEmpty) count++;
    return count;
  }

  Future<void> _refreshPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from('pets')
          .select('id, name, type, gender, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _pets = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      _filterAndSortPets();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to get pet statistics
  Map<String, int> _getPetStats() {
    final stats = <String, int>{
      'total': _pets.length,
      'cats': _pets.where((pet) => pet['type']?.toString().toLowerCase() == 'cat').length,
      'dogs': _pets.where((pet) => pet['type']?.toString().toLowerCase() == 'dog').length,
      'males': _pets.where((pet) => pet['gender']?.toString().toLowerCase() == 'male').length,
      'females': _pets.where((pet) => pet['gender']?.toString().toLowerCase() == 'female').length,
    };
    return stats;
  }

  static IconData _getPetIcon(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return FontAwesomeIcons.dog;
      case 'cat':
        return FontAwesomeIcons.cat;
      case 'bird':
        return FontAwesomeIcons.dove;
      case 'fish':
        return FontAwesomeIcons.fish;
      case 'hamster':
        return FontAwesomeIcons.kiwiBird;
      default:
        return FontAwesomeIcons.paw;
    }
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final createdAt = DateTime.parse(pet['created_at'] ?? DateTime.now().toIso8601String());
    final daysSinceAdded = DateTime.now().difference(createdAt).inDays;
    final addedText = daysSinceAdded == 0
        ? 'Added today'
        : daysSinceAdded == 1
            ? 'Added yesterday'
            : 'Added ${daysSinceAdded}d ago';

    return Card(
      elevation: 2,
      shadowColor: primaryBlue.withValues(alpha: 0.1),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailsPage(pet: pet),
            ),
          );
          // Refresh pets list if changes were made
          if (result == true) {
            _refreshPets();
          }
        },
        borderRadius: BorderRadius.circular(14),
        splashColor: primaryBlue.withValues(alpha: 0.05),
        highlightColor: primaryBlue.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet Icon Container with enhanced design
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryBlue.withValues(alpha: 0.1),
                        primaryBlue.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryBlue.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: FaIcon(
                      _getPetIcon(pet['type'] ?? ''),
                      size: 24,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pet Name with enhanced typography
              Center(
                child: Text(
                  pet['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textPrimary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),

              // Pet Type and Gender with improved styling
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: primaryBlue.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${pet['type'] ?? 'Unknown'} • ${pet['gender'] ?? 'Unknown'}',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Added date with subtle styling
              Center(
                child: Text(
                  addedText,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getPetStats();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'All My Pets',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: primaryBlue),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPetAccountScreen()),
              );
              if (result == true) {
                _refreshPets();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPets,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Enhanced Statistics Header
                _buildStatsHeader(stats),

                // Enhanced Search and Filter Section
                _buildSearchAndFilters(),

                // Pets Grid with enhanced design
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: primaryBlue),
                              SizedBox(height: 16),
                              Text(
                                'Loading your pets...',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filteredPets.isEmpty
                          ? _buildEmptyState()
                          : _buildPetsGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Compact Statistics Header Widget
  Widget _buildStatsHeader(Map<String, int> stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pet Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${stats['total']} Total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: FontAwesomeIcons.cat,
                  label: 'Cats',
                  count: stats['cats']!,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  icon: FontAwesomeIcons.dog,
                  label: 'Dogs',
                  count: stats['dogs']!,
                  color: secondaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.male,
                  label: 'Males',
                  count: stats['males']!,
                  color: successGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.female,
                  label: 'Females',
                  count: stats['females']!,
                  color: Colors.pink[400]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Enhanced Search and Filter Section with Collapsible Design
  Widget _buildSearchAndFilters() {
    final activeFilterCount = _getActiveFilterCount();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar and Filter Toggle Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search pets by name, type, or gender...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: primaryBlue, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _filterAndSortPets();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryBlue, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Toggle Header
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleFilterExpansion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _hasActiveFilters ? primaryBlue.withValues(alpha: 0.1) : backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _hasActiveFilters ? primaryBlue.withValues(alpha: 0.3) : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune,
                                color: _hasActiveFilters ? primaryBlue : textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filters',
                                style: TextStyle(
                                  color: _hasActiveFilters ? primaryBlue : textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (activeFilterCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    activeFilterCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Icon(
                                _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
                                color: _hasActiveFilters ? primaryBlue : textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearAllFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear_all, color: Colors.red[600], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Expandable Filter Options
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            constraints: _isFilterExpanded
                ? const BoxConstraints(maxHeight: 400)
                : const BoxConstraints(maxHeight: 0),
            child: _isFilterExpanded
                ? SingleChildScrollView(child: _buildExpandedFilters())
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Expanded Filter Options Section
  Widget _buildExpandedFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 16),

          // Pet Type Filter Section
          _buildFilterSection(
            title: 'Pet Type',
            icon: Icons.pets,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', _selectedTypeFilter == 'All', () => _updateTypeFilter('All')),
                  _buildFilterChip('Cats', _selectedTypeFilter == 'Cat', () => _updateTypeFilter('Cat')),
                  _buildFilterChip('Dogs', _selectedTypeFilter == 'Dog', () => _updateTypeFilter('Dog')),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gender Filter Section
          _buildFilterSection(
            title: 'Gender',
            icon: Icons.wc,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', _selectedGenderFilter == 'All', () => _updateGenderFilter('All')),
                  _buildFilterChip('Male', _selectedGenderFilter == 'Male', () => _updateGenderFilter('Male')),
                  _buildFilterChip('Female', _selectedGenderFilter == 'Female', () => _updateGenderFilter('Female')),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sort Options Section
          _buildFilterSection(
            title: 'Sort By',
            icon: Icons.sort,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSortChip('Newest First', _sortBy == 'newest', () => _updateSorting('newest')),
                  _buildSortChip('Oldest First', _sortBy == 'oldest', () => _updateSorting('oldest')),
                  _buildSortChip('Name A-Z', _sortBy == 'name', () => _updateSorting('name')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: primaryBlue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? secondaryBlue : backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? secondaryBlue : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: secondaryBlue.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }

  // Enhanced Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                size: 60,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hasActiveFilters
                  ? 'No pets found'
                  : 'No pets added yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _hasActiveFilters
                  ? 'Try adjusting your search terms or filters'
                  : 'Add your first pet to get started!',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_hasActiveFilters)
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPetAccountScreen()),
                  );
                  if (result == true) {
                    _refreshPets();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Pet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Optimized Pets Grid with Lazy Loading
  Widget _buildPetsGrid() {
    // Show skeleton loading during initial load
    if (_isInitialLoading) {
      return SkeletonScreens.gridSkeleton(
        itemCount: 6,
        itemBuilder: () => SkeletonScreens.petCardSkeleton(),
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      );
    }

    // Use filtered pets if search/filter is active, otherwise use lazy loading
    if (_hasActiveFilters) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _filteredPets.length,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              child: _buildPetCard(_filteredPets[index]),
            );
          },
        ),
      );
    }

    // Use lazy loading for unfiltered view
    return LazyLoadingGridView<Map<String, dynamic>>(
      service: _lazyLoadingService,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemBuilder: (context, pet, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: _buildPetCard(pet),
        );
      },
      loadingWidget: SkeletonScreens.petCardSkeleton(),
      emptyWidget: _buildEmptyState(),
      errorWidget: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load pets',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh and try again',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}