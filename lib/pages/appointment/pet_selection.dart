import 'package:flutter/material.dart';
import 'package:pet_smart/pages/appointment/time.dart';

// Color constants for consistency
const Color primaryRed = Color(0xFFE57373);
const Color primaryBlue = Color(0xFF3F51B5);
const Color accentRed = Color(0xFFEF5350);
const Color backgroundColor = Color(0xFFF6F7FB);
const Color primaryGreen = Color(0xFF4CAF50);

class PetModel {
  final String id;
  final String name;
  final String species;
  final String breed;
  final String imageUrl;
  final String age;

  PetModel({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.imageUrl,
    required this.age,
  });
}

class PetSelectionPage extends StatefulWidget {
  final DateTime selectedDate;
  
  const PetSelectionPage({
    super.key, 
    required this.selectedDate,
  });

  @override
  State<PetSelectionPage> createState() => _PetSelectionPageState();
}

class _PetSelectionPageState extends State<PetSelectionPage> {
  // Demo pets data
  final List<PetModel> _pets = [
    PetModel(
      id: '1', 
      name: 'Max', 
      species: 'Dog',
      breed: 'Golden Retriever',
      imageUrl: 'assets/pets/dog1.png',
      age: '3 years',
    ),
    PetModel(
      id: '2', 
      name: 'Bella', 
      species: 'Dog',
      breed: 'Poodle',
      imageUrl: 'assets/pets/dog2.png',
      age: '1 year',
    ),
    PetModel(
      id: '3', 
      name: 'Whiskers', 
      species: 'Cat',
      breed: 'Tabby',
      imageUrl: 'assets/pets/cat1.png',
      age: '2 years',
    ),
    PetModel(
      id: '4', 
      name: 'Daisy', 
      species: 'Cat',
      breed: 'Persian',
      imageUrl: 'assets/pets/cat2.png',
      age: '4 years',
    ),
  ];
  
  PetModel? selectedPet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Your Pet',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Choose a pet for this appointment:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _pets.length,
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  final bool isSelected = selectedPet?.id == pet.id;
                  
                  return PetCard(
                    pet: pet,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        selectedPet = pet;
                      });
                    },
                  );
                },
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: selectedPet == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AppointmentTimePage(),
                          ),
                        );
                      },
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _showAddPetDialog(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Add New Pet', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Pet'),
        content: const Text('This feature will allow you to add a new pet to your profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class PetCard extends StatelessWidget {
  final PetModel pet;
  final bool isSelected;
  final VoidCallback onTap;
  
  const PetCard({
    super.key,
    required this.pet,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: pet.imageUrl.startsWith('assets')
                      ? Image.asset(
                          pet.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              pet.species == 'Dog' ? Icons.pets : Icons.catching_pokemon,
                              size: 40,
                              color: Colors.grey[500],
                            );
                          },
                        )
                      : Icon(
                          pet.species == 'Dog' ? Icons.pets : Icons.catching_pokemon,
                          size: 40,
                          color: Colors.grey[500],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.species} • ${pet.breed}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Age: ${pet.age}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const CircleAvatar(
                  backgroundColor: primaryBlue,
                  radius: 12,
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}