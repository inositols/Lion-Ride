import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/overview_view.dart';
import 'views/verification_view.dart';
import 'views/transaction_view.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Dashboard Overview',
    'Rider Verifications',
    'Transaction Ledger',
    'User Management',
  ];

  final List<IconData> _icons = [
    Icons.dashboard_outlined,
    Icons.verified_user_outlined,
    Icons.receipt_long_outlined,
    Icons.people_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F7F9),
          appBar: isDesktop
              ? null
              : AppBar(
                  title: ValueListenableBuilder<int>(
                    valueListenable: _selectedIndex,
                    builder: (context, index, _) => Text(
                      _titles[index],
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
          drawer: isDesktop ? null : _buildSidebar(isDrawer: true),
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(isDrawer: false),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _selectedIndex,
                  builder: (context, index, _) {
                    return _buildContent(index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      width: 280,
      color: const Color(0xFF004D40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NSURIDE',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Admin Console',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _titles.length,
              itemBuilder: (context, index) {
                return ValueListenableBuilder<int>(
                  valueListenable: _selectedIndex,
                  builder: (context, selectedIndex, _) {
                    final bool isSelected = selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        onTap: () {
                          _selectedIndex.value = index;
                          if (isDrawer) Navigator.pop(context);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                        leading: Icon(
                          _icons[index],
                          color: isSelected ? const Color(0xFFFFC107) : Colors.white70,
                        ),
                        title: Text(
                          _titles[index],
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            leading: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              'User Admin',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Sign Out',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
            ),
            onTap: () {
              // Sign out logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return const OverviewView();
      case 1:
        return const VerificationView();
      case 2:
        return const TransactionView();
      case 3:
      default:
        return const Center(child: Text('User Management - Coming Soon'));
    }
  }
}
