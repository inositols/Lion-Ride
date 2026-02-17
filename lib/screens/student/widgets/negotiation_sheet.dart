import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nsuride_mobile/logic/location/location_bloc.dart';

class NegotiationSheet extends StatefulWidget {
  final RouteLoaded routeState;
  final Function(double finalPrice, List<String> notes) onConfirm;

  const NegotiationSheet({
    super.key,
    required this.routeState,
    required this.onConfirm,
  });

  @override
  State<NegotiationSheet> createState() => _NegotiationSheetState();
}

class _NegotiationSheetState extends State<NegotiationSheet> {
  late double _currentPrice;
  final List<String> _selectedNotes = [];
  final List<String> _quickNotes = [
    "I have luggage",
    "2 Passengers",
    "Cash",
    "Transfer",
  ];

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.routeState.price.toDouble();
  }

  void _adjustPrice(double amount) {
    setState(() {
      _currentPrice = (_currentPrice + amount).clamp(200, 10000);
    });
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF004D40);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Make Your Offer',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: tealColor,
            ),
          ),
          const SizedBox(height: 20),

          // Route Summary Visualization
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 12, color: tealColor),
                    Container(width: 2, height: 30, color: Colors.grey[300]),
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.routeState.pickup,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 25),
                      Text(
                        widget.routeState.dropoff,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Price Adjuster
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAdjustButton(Icons.remove, () => _adjustPrice(-50)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        '₦${_currentPrice.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: tealColor,
                        ),
                      ),
                    ),
                    _buildAdjustButton(Icons.add, () => _adjustPrice(50)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Recommended: ₦${widget.routeState.price}',
                  style: GoogleFonts.inter(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Quick Notes
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _quickNotes.map((note) {
                final isSelected = _selectedNotes.contains(note);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(note),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        val
                            ? _selectedNotes.add(note)
                            : _selectedNotes.remove(note);
                      });
                    },
                    selectedColor: tealColor.withOpacity(0.1),
                    checkmarkColor: tealColor,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: isSelected ? tealColor : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected ? tealColor : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 30),

          // Action Button
          ElevatedButton(
            onPressed: () => widget.onConfirm(_currentPrice, _selectedNotes),
            style: ElevatedButton.styleFrom(
              backgroundColor: tealColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            child: Text(
              'REQUEST RIDE',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAdjustButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, color: const Color(0xFF004D40)),
      ),
    );
  }
}
