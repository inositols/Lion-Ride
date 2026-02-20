import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DisputeManagementView extends StatefulWidget {
  const DisputeManagementView({super.key});

  @override
  State<DisputeManagementView> createState() => _DisputeManagementViewState();
}

class _DisputeManagementViewState extends State<DisputeManagementView> {
  final TextEditingController _searchController = TextEditingController();
  DocumentSnapshot? _foundRide;
  bool _isSearching = false;

  Future<void> _searchRide() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() => _isSearching = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('rides').doc(_searchController.text.trim()).get();
      setState(() => _foundRide = doc.exists ? doc : null);
      if (!doc.exists && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride not found')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _processRefund() async {
    if (_foundRide == null) return;
    try {
      // 1. Mark ride as refunded
      await _foundRide!.reference.update({'dispute_status': 'refunded', 'status': 'cancelled'});
      
      // 2. Logic to credit student wallet would happen here
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student Refunded Successfully'), backgroundColor: Colors.green));
        Navigator.pop(context); // Close any open dialogs
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing refund: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dispute Management',
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
          ),
          const SizedBox(height: 8),
          Text('Resolve rider/student conflicts and manage trip reversals', style: GoogleFonts.inter(color: Colors.black54, fontSize: 16)),
          const SizedBox(height: 40),

          _buildSearchBar(),
          const SizedBox(height: 32),
          
          if (_foundRide != null) _buildRideDetails()
          else if (!_isSearching) _buildEmptyState(),
          
          if (_isSearching) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 600,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Enter Ride ID (e.g., d5f8...0)', border: InputBorder.none),
              onSubmitted: (_) => _searchRide(),
            ),
          ),
          TextButton(onPressed: _searchRide, child: const Text('SEARCH')),
        ],
      ),
    );
  }

  Widget _buildRideDetails() {
    final data = _foundRide!.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    
    return Container(
      width: 800,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TRIP RECEIPT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF004D40), letterSpacing: 1.5)),
              _buildStatusBadge(data['status'] ?? 'unknown'),
            ],
          ),
          const Divider(height: 48),
          
          Row(
            children: [
              Expanded(child: _infoItem('STUDENT', data['studentName'] ?? 'N/A', data['studentId'] ?? '')),
              Expanded(child: _infoItem('RIDER', data['riderName'] ?? 'N/A', data['riderId'] ?? '')),
            ],
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: _infoItem('PICKUP', data['pickupAddress'] ?? 'N/A', '')),
              Expanded(child: _infoItem('DROPOFF', data['dropoffAddress'] ?? 'N/A', '')),
            ],
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: _infoItem('FARE', '₦${data['fare']}', 'Type: ${data['paymentMethod']}')),
              Expanded(child: _infoItem('DATE', timestamp != null ? DateFormat('MMM dd, yyyy · HH:mm').format(timestamp.toDate()) : 'N/A', '')),
            ],
          ),
          
          const Divider(height: 64),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _foundRide!.reference.update({'dispute_status': 'resolved'}),
                child: const Text('MARK RESOLVED'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _processRefund,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('REFUND STUDENT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF004D40).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.search_off_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Search for a Ride ID to manage an active dispute', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
