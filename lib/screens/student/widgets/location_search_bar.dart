import 'package:flutter/material.dart';
import '../../../repositories/location_repository.dart';

class LocationSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onMenuTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final List<Place> searchResults;
  final Function(Place) onSelectPlace;

  const LocationSearchBar({
    super.key,
    required this.controller,
    required this.onMenuTap,
    required this.onChanged,
    required this.onClear,
    required this.searchResults,
    required this.onSelectPlace,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Where to?',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.menu, color: Color(0xFF004D40)),
                        onPressed: onMenuTap,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: onClear,
                            )
                          : null,
                    ),
                    onChanged: onChanged,
                  ),
                  // Search Results List
                  if (searchResults.isNotEmpty) ...[
                    const Divider(height: 1, thickness: 0.5),
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 250,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: searchResults.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, thickness: 0.5, indent: 60, color: Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final place = searchResults[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFFFC107),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            subtitle: Text(
                              'Nsukka, Nigeria',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            onTap: () => onSelectPlace(place),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
