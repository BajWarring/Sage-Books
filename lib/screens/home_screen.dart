import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Needed for Hive
import 'package:sage/models/cashbook.dart';       // Needed for Cashbook model
import 'package:sage/screens/cashbook_tab.dart';
import 'package:sage/screens/profile_tab.dart';
import 'package:sage/screens/settings_tab.dart';
import 'package:hive/hive.dart';
import 'package:sage/models/entry.dart';


const Color _primaryOrange = Color(0xFFF15A24);
const Color _textMedium = Color(0xFF5F5F5F);
const Color _bgLightGrey = Color(0xFFF9F9F9);
const Color _bgWhite = Color(0xFFFFFFFF);
const Color _borderLight = Color(0xFFECECEC);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSearching = false;
  bool _isProfileOpen = false;

  final TextEditingController _searchController = TextEditingController();

  final List<Widget> _pages = [
    CashbookTab(searchController: TextEditingController()),
    const SettingsTab(),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _toggleProfile() {
    setState(() {
      _isProfileOpen = !_isProfileOpen;
    });
  }

  
  void _onAddCashbook() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Cashbook'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Cashbook Name',
            hintText: 'e.g. Office, Home, Travel',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _primaryOrange),
            child: const Text('Create'),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                 ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                 );
                 return;
              }

              // Store the Navigator and ScaffoldMessenger before the async gap.
              final navigator = Navigator.of(dialogContext);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                // 1. Ensure boxes are open (Safety Check)
                if (!Hive.isBoxOpen('cashbooks')) {
                   await Hive.openBox<Cashbook>('cashbooks');
                }
                // The 'entries' box is needed for the HiveList inside the cashbook
                if (!Hive.isBoxOpen('entries')) {
                   await Hive.openBox<Entry>('entries');
                }

                // 2. Create the object
                final box = Hive.box<Cashbook>('cashbooks');
                final entriesBox = Hive.box<Entry>('entries');
                
                final newBook = Cashbook(
                  name: name,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  // Initialize with an empty HiveList linked to the entries box
                  entries: HiveList(entriesBox), 
                );

                // 3. Save to database
                await box.add(newBook);
                debugPrint("Cashbook '$name' created successfully.");

                // 4. Close dialog and show success
                if (!mounted) return;
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Cashbook "$name" created!'),
                      backgroundColor: Colors.green,
                    ),
                  );
              } catch (e) {
                // 5. CATCH ERRORS: This will tell us why it was failing silently
                debugPrint("Error creating cashbook: $e");
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    return Scaffold(
      backgroundColor: _bgLightGrey,
      body: Stack(
        children: [
          // Main App Content
          Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(context),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),

          // Sliding Profile Page
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            top: 0,
            bottom: 0,
            right: _isProfileOpen ? 0 : -mediaQuery.size.width,
            width: mediaQuery.size.width,
            child: ProfileTab(
              onBackTapped: _toggleProfile,
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // --- FIX 2: Use Scale + Slide to hide FAB completely ---
  Widget _buildFab(BuildContext context) {
    // Hide if profile is open OR if we are not on the Cashbook tab
    bool isFabVisible = _selectedIndex == 0 && !_isProfileOpen;

    return AnimatedScale(
      scale: isFabVisible ? 1.0 : 0.0, // Shrink to 0 when hidden
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton(
        onPressed: _onAddCashbook, // Calls the new dialog logic
        backgroundColor: _primaryOrange,
        shape: const CircleBorder(),
        elevation: 8.0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ... (Keep existing _buildAppBar, _buildSearchBar, _buildBottomNav methods below exactly as they were) ...
  
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 60.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _toggleProfile,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.person, color: _primaryOrange),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text('Personal Account',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search,
                          color: Colors.white),
                      onPressed: _toggleSearch,
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Filter clicked!')));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      height: _isSearching ? 60.0 : 0.0,
      decoration: const BoxDecoration(
        color: _bgWhite,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search cashbooks...',
            prefixIcon: const Icon(Icons.search, color: _textMedium),
            filled: true,
            fillColor: _bgLightGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: _bgWhite,
        border: Border(top: BorderSide(color: _borderLight, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.book,
            label: 'Cashbooks',
            isActive: _selectedIndex == 0,
            onPressed: () => _onItemTapped(0),
          ),
          _buildNavItem(
            icon: Icons.settings,
            label: 'Settings',
            isActive: _selectedIndex == 1,
            onPressed: () => _onItemTapped(1),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final Color color = isActive ? _primaryOrange : _textMedium;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
