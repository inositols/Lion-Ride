import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRoleDialog(BuildContext context, String uid, String currentRole) {
    String selectedRole = currentRole;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change User Role', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['student', 'rider', 'admin'].map((role) => RadioListTile<String>(
              title: Text(role.toUpperCase(), style: GoogleFonts.inter()),
              value: role,
              groupValue: selectedRole,
              onChanged: (val) => setDialogState(() => selectedRole = val!),
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': selectedRole});
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white),
              child: const Text('UPDATE ROLE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                  ),
                  const SizedBox(height: 8),
                  Text('Oversee all registered students, riders, and administrators', style: GoogleFonts.inter(color: Colors.black54, fontSize: 16)),
                ],
              ),
              _buildSearchAndFilter(),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    
                    var docs = snapshot.data?.docs ?? [];
                    
                    // Client-side filtering for demonstration/simplicity
                    var users = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      final role = (data['role'] ?? '').toString();
                      
                      final matchesSearch = name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
                      final matchesRole = _selectedRole == 'All' || role == _selectedRole.toLowerCase();
                      
                      return matchesSearch && matchesRole;
                    }).toList();

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 360),
                          child: DataTable(
                            headingRowHeight: 64,
                            dataRowMaxHeight: 72,
                            headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                            columns: const [
                              DataColumn(label: Text('NAME')),
                              DataColumn(label: Text('EMAIL')),
                              DataColumn(label: Text('PHONE')),
                              DataColumn(label: Text('ROLE')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('ACTION')),
                            ],
                            rows: users.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final role = data['role'] ?? 'student';
                              final status = data['status'] ?? 'active';
                              final bool isSuspended = data['is_suspended'] ?? false;
                              final double balance = (data['wallet_balance'] ?? 0.0).toDouble();

                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>((states) {
                                  if (isSuspended) return Colors.red.withOpacity(0.05);
                                  return null;
                                }),
                                cells: [
                                  DataCell(Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                                  DataCell(Text(data['email'] ?? 'N/A')),
                                  DataCell(Text(data['phone'] ?? 'N/A')),
                                  DataCell(_buildRoleBadge(role)),
                                  DataCell(Text('₦${NumberFormat('#,###').format(balance)}')),
                                  DataCell(_buildStatusBadge(isSuspended ? 'suspended' : status)),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      onSelected: (val) async {
                                        if (val == 'role') {
                                          _showRoleDialog(context, doc.id, role);
                                        } else if (val == 'suspend') {
                                          await FirebaseFirestore.instance.collection('users').doc(doc.id).update({
                                            'is_suspended': !isSuspended,
                                          });
                                        } else if (val == 'reset_pin') {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet PIN Reset initiated')));
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'profile', child: Text('View Profile')),
                                        const PopupMenuItem(value: 'role', child: Text('Change Role')),
                                        PopupMenuItem(value: 'suspend', child: Text(isSuspended ? 'Unsuspend User' : 'Suspend Account')),
                                        const PopupMenuItem(value: 'reset_pin', child: Text('Reset Wallet PIN')),
                                      ],
                                      icon: const Icon(Icons.more_vert),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: 'Search users...',
              border: InputBorder.none,
              icon: Icon(Icons.search, color: Colors.grey, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              items: ['All', 'Student', 'Rider', 'Admin'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.blue;
    if (role == 'rider') color = Colors.orange;
    if (role == 'admin') color = const Color(0xFF004D40);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isActive = status == 'active';
    bool isSuspended = status == 'suspended';
    Color color = isActive ? Colors.green : (isSuspended ? Colors.red : Colors.grey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
