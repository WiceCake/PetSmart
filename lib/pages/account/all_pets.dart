import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pet_details.dart';

class AllPetsPage extends StatefulWidget {
  final List<Map<String, dynamic>> pets;

  const AllPetsPage({super.key, required this.pets});

  @override
  State<AllPetsPage> createState() => _AllPetsPageState();
}

class _AllPetsPageState extends State<AllPetsPage> {
  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _filteredPets = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pets = List.from(widget.pets);
    _filteredPets = List.from(_pets);
    _searchController.addListener(_filterPets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPets = _pets.where((pet) {
        final name = (pet['name'] ?? '').toString().toLowerCase();
        final type = (pet['type'] ?? '').toString().toLowerCase();
        final gender = (pet['gender'] ?? '').toString().toLowerCase();
        return name.contains(query) || type.contains(query) || gender.contains(query);
      }).toList();
    });
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
        _filteredPets = List.from(_pets);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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
    const primaryColor = Color(0xFF233A63);

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pet Icon Container
              Expanded(
                flex: 3,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      _getPetIcon(pet['type'] ?? ''),
                      size: 24,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Pet Name - Fixed height to ensure descenders are visible
              Container(
                height: 20, // Fixed height to ensure descenders are visible
                alignment: Alignment.center,
                child: Text(
                  pet['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: primaryColor,
                    height: 1.2, // Line height to accommodate descenders
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              // Pet Type and Gender - Fixed height for consistent layout
              Container(
                height: 16, // Fixed height for consistent layout
                alignment: Alignment.center,
                child: Text(
                  '${pet['type'] ?? 'Unknown'} • ${pet['gender'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2, // Line height for better text rendering
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    const primaryColor = Color(0xFF233A63);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'All My Pets',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPets,
        child: Column(
          children: [
            // Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search pets by name, type, or gender...',
                  prefixIcon: const Icon(Icons.search, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            // Pets Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'No pets found matching your search'
                                    : 'No pets found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'Try adjusting your search terms'
                                    : 'Add your first pet to get started!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _filteredPets.length,
                            itemBuilder: (context, index) {
                              return _buildPetCard(_filteredPets[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
