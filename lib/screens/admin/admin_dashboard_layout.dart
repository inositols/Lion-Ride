import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/overview_view.dart';
import 'views/verification_center_view.dart';
import 'views/transaction_ledger_view.dart';
import 'views/user_management_view.dart';
import 'views/pricing_settings_view.dart';
import 'views/live_map_view.dart';
import 'views/dispute_management_view.dart';
import 'views/broadcast_view.dart';

class AdminDashboardLayout extends StatefulWidget {
  const AdminDashboardLayout({super.key});

  @override
  State<AdminDashboardLayout> createState() => _AdminDashboardLayoutState();
}

class _AdminDashboardLayoutState extends State<AdminDashboardLayout> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<({String title, IconData icon, Widget view})> _menuItems = [
    (title: 'Overview', icon: Icons.analytics_outlined, view: const OverviewView()),
    (title: 'Live Map', icon: Icons.map_outlined, view: const LiveMapView()),
    (title: 'Users', icon: Icons.people_outline, view: const UserManagementView()),
    (title: 'Verifications', icon: Icons.verified_user_outlined, view: const VerificationCenterView()),
    (title: 'Ledger', icon: Icons.credit_card_outlined, view: const TransactionLedgerView()),
    (title: 'Pricing', icon: Icons.payments_outlined, view: const PricingSettingsView()),
    (title: 'Disputes', icon: Icons.gavel_outlined, view: const DisputeManagementView()),
    (title: 'Broadcast', icon: Icons.campaign_outlined, view: const BroadcastView()),
  ];

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndex,
      builder: (context, index, child) {
        final double width = MediaQuery.of(context).size.width;
        final bool isDesktop = width > 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: isDesktop
              ? null
              : AppBar(
                  backgroundColor: const Color(0xFF004D40),
                  elevation: 0,
                  title: Text(
                    _menuItems[index].title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
          drawer: isDesktop ? null : _buildDrawer(index),
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(index),
              Expanded(
                child: _menuItems[index].view,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(int currentIndex) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF004D40),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 32),
          ...List.generate(_menuItems.length, (i) => _buildNavItem(i, _menuItems[i].icon, _menuItems[i].title, currentIndex == i)),
          const Spacer(),
          _buildAdminProfile(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF004D40), size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            'NSURIDE',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectedIndex.value = index,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFFFFC107) : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(int currentIndex) {
    return Drawer(
      child: Container(
        color: const Color(0xFF004D40),
        child: Column(
          children: [
            _buildLogo(),
            ...List.generate(_menuItems.length, (i) => ListTile(
              leading: Icon(_menuItems[i].icon, color: currentIndex == i ? const Color(0xFFFFC107) : Colors.white70),
              title: Text(_menuItems[i].title, style: TextStyle(color: currentIndex == i ? Colors.white : Colors.white70, fontWeight: currentIndex == i ? FontWeight.bold : FontWeight.normal)),
              onTap: () {
                _selectedIndex.value = i;
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfile() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Icon(Icons.shield_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin Panel',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Primary Admin',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
