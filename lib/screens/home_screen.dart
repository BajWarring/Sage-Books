import 'package:flutter/material.dart';
import 'package:sage/models/cashflow.dart';
import 'package:sage/screens/cashbook_tab.dart';
import 'package:sage/screens/entry_form_screen.dart';
import 'package:sage/screens/profile_tab.dart';
import 'package:sage/screens/settings_tab.dart';
import 'package:sage/utils/transitions.dart';

// --- NEW: Colors from HTML mockup ---
const Color _primaryOrange = Color(0xFFFF6B00);
const Color _textMedium = Color(0xFF5F5F5F);
const Color _bgLightGrey = Color(0xFFF9F9F9);
const Color _bgWhite = Color(0xFFFFFFFF);
const Color _borderLight = Color(0xFFECECEC);
// --- End New Colors ---

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

  late AnimationController _fabAnimationController;
  late Animation<Offset> _fabAnimation;

  // This controller will be passed to the CashbookTab
  final TextEditingController _searchController = TextEditingController();

  final List<Widget> _pages = [
    // We pass the search controller down to the cashbook tab
    CashbookTab(searchController: TextEditingController()),
    const SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fabAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.15),
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
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
    // This logic is moved from CashbookTab
    // You need to implement _showCreateCashbookDialog here or pass the context
    // For now, let's use the Add Entry screen as a placeholder
    Navigator.of(context).push(
      SlideRightRoute(
        page: const EntryFormScreen(
          cashbookName: "Your Default Cashbook", // This needs to be dynamic
          initialCashFlow: CashFlow.cashIn,
        ),
      ),
    );
    // In a real app, you'd call the _showCreateCashbookDialog
    // from cashbook_tab.dart. For simplicity, I'll pop a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Cashbook functionality goes here!')),
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

  // --- NEW: Custom AppBar from HTML ---
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
                // Left: Profile
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
                // Right: Icons
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

  // --- NEW: Animated Search Bar ---
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

  // --- NEW: Animated FAB from HTML ---
  Widget _buildFab(BuildContext context) {
    bool isFabVisible = _selectedIndex == 0 && !_isProfileOpen;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: isFabVisible ? Offset.zero : const Offset(0, 2),
      child: SlideTransition(
        position: _fabAnimation,
        child: FloatingActionButton(
          onPressed: _onAddCashbook,
          backgroundColor: _primaryOrange,
          shape: const CircleBorder(),
          elevation: 8.0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // --- NEW: Custom Bottom Navigation Bar ---
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 70, // Extra padding for safe area
      decoration: const BoxDecoration(
        color: _bgWhite,
        border: Border(top: BorderSide(color: _borderLight, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.only(bottom: 20, top: 8), // Padding for notch
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