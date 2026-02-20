import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastView extends StatefulWidget {
  const BroadcastView({super.key});

  @override
  State<BroadcastView> createState() => _BroadcastViewState();
}

class _BroadcastViewState extends State<BroadcastView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'All Users';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('system_broadcasts').add({
        'title': _titleController.text,
        'body': _bodyController.text,
        'target_audience': _audience.toLowerCase().replaceAll(' ', '_'),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // Picked up by Cloud Functions
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast queued successfully!'), backgroundColor: Colors.green));
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Broadcast Center',
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
              ),
              const SizedBox(height: 8),
              Text('Send mass push notifications to your platform users', style: GoogleFonts.inter(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compose Message', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF004D40))),
                    const SizedBox(height: 32),
                    
                    _buildLabel('Notification Title'),
                    TextField(
                      controller: _titleController,
                      decoration: _inputDecoration('e.g. System Maintenance Update'),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Notification Body'),
                    TextField(
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: _inputDecoration('Enter your message here...'),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Target Audience'),
                    _buildAudienceSelector(),
                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendBroadcast,
                        icon: const Icon(Icons.send),
                        label: Text(_isSending ? 'SENDING...' : 'SEND BROADCAST', style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildAudienceSelector() {
    return Row(
      children: ['All Users', 'Students Only', 'Riders Only'].map((option) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            onPressed: () => setState(() => _audience = option),
            style: OutlinedButton.styleFrom(
              backgroundColor: _audience == option ? const Color(0xFF004D40).withOpacity(0.05) : Colors.transparent,
              side: BorderSide(color: _audience == option ? const Color(0xFF004D40) : Colors.grey.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(option, style: TextStyle(color: _audience == option ? const Color(0xFF004D40) : Colors.black54, fontWeight: _audience == option ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      )).toList(),
    );
  }
}
