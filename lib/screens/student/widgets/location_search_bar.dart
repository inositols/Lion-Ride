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
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Where to?',
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: onMenuTap,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: onClear,
                            )
                          : null,
                    ),
                    onChanged: onChanged,
                  ),
                  // Search Results List
                  if (searchResults.isNotEmpty)
                    Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: searchResults.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = searchResults[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Color(0xFFFFC107),
                              ),
                              title: Text(place.name),
                              onTap: () => onSelectPlace(place),
                            );
                          },
                        ),
                      ),
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
