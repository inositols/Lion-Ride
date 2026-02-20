import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingSettingsView extends StatefulWidget {
  const PricingSettingsView({super.key});

  @override
  State<PricingSettingsView> createState() => _PricingSettingsViewState();
}

class _PricingSettingsViewState extends State<PricingSettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _baseFareController = TextEditingController();
  final _perKmController = TextEditingController();
  final _minFareController = TextEditingController();
  double _nightSurge = 1.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _baseFareController.dispose();
    _perKmController.dispose();
    _minFareController.dispose();
    super.dispose();
  }

  Future<void> _updatePricing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('system').doc('pricing').set({
        'base_fare': double.parse(_baseFareController.text),
        'cost_per_km': double.parse(_perKmController.text),
        'min_fare': double.parse(_minFareController.text),
        'night_surge_multiplier': _nightSurge,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pricing updated successfully!'), backgroundColor: Colors.green),
        );
      }
      // NOTE: Reminder to update PricingService to read from this document instead of hardcoded values.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating pricing: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pricing Settings',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage platform fares and service costs in real-time',
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 40),
              
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('system').doc('pricing').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    _baseFareController.text = (data['base_fare'] ?? '').toString();
                    _perKmController.text = (data['cost_per_km'] ?? '').toString();
                    _minFareController.text = (data['min_fare'] ?? '').toString();
                    _nightSurge = (data['night_surge_multiplier'] ?? 1.0).toDouble();
                  }

                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Base Fare (₦)'),
                          TextFormField(
                            controller: _baseFareController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('e.g. 200'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 24),
                          
                          _buildFieldLabel('Cost Per Kilometer (₦)'),
                          TextFormField(
                            controller: _perKmController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('e.g. 50'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 24),

                          _buildFieldLabel('Minimum Ride Fare (₦)'),
                          TextFormField(
                            controller: _minFareController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('e.g. 400'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 32),

                          _buildFieldLabel('Night Surge Multiplier (${_nightSurge.toStringAsFixed(1)}x)'),
                          Slider(
                            value: _nightSurge,
                            min: 1.0,
                            max: 3.0,
                            divisions: 20,
                            activeColor: const Color(0xFF004D40),
                            onChanged: (val) => setState(() => _nightSurge = val),
                          ),
                          const SizedBox(height: 48),

                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updatePricing,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004D40),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('UPDATE LIVE PRICING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
