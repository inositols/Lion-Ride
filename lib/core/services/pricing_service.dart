class PricingService {
  // Constants for Nsukka economy
  static const double baseFare = 200.0;
  static const double costPerKm = 110.0;
  static const double minFare = 300.0;
  static const double nightSurgeMultiplier = 1.3;
  static const double roadFactor = 1.4;

  /// Calculates the fare based on distance in meters
  static double calculateFare(double distanceInMeters) {
    // Convert to km and apply road factor for curvy Nsukka roads
    double distanceInKm = (distanceInMeters / 1000) * roadFactor;

    // Base formula
    double rawPrice = baseFare + (distanceInKm * costPerKm);

    // Night Surge Logic (8 PM to 6 AM)
    if (_isNightTime()) {
      rawPrice *= nightSurgeMultiplier;
    }

    // Minimum Fare (Floor Logic)
    if (rawPrice < minFare) {
      rawPrice = minFare;
    }

    // Rounding to nearest ₦50 for cash convenience
    return (rawPrice / 50).round() * 50.0;
  }

  static bool _isNightTime() {
    final int hour = DateTime.now().hour;
    return hour >= 20 || hour < 6;
  }

  /// Benchmark check: Fada Agbo to Beach (~2.8km)
  /// (2.8 * 1.4) = 3.92km
  /// 200 + (3.92 * 110) = 200 + 431.2 = 631.2
  /// Rounded to nearest 50 = 650?
  ///
  /// Wait, the user said "Fada Agbo Junction to Beach Junction (~2.8km) costs ₦500".
  /// Let's re-check the user's ground truth.
  /// If distance is 2.8km:
  /// (2.8 * 1.4) = 3.92km
  /// 200 + (3.92 * 110) = 631.2
  /// This rounds to 650.
  ///
  /// If road factor is NOT applied before the cost:
  /// 200 + (2.8 * 110) = 200 + 308 = 508.
  /// This rounds to 500.
  ///
  /// Ah! The user said: "Formula: rawPrice = baseFare + (distanceInKm * costPerKm)".
  /// And "Convert to km and multiply by 1.4 (Road Factor)".
  /// Does the "Road Factor" apply to the distance used in the formula?
  /// Most likely yes, as it's meant to account for actual road distance.
  /// BUT if 2.8km is already the ROAD distance (curvy), then 1.4 should NOT be applied again.
  /// Usually, mapping APIs return linear distance "as the crow flies", hence the multiplier.
  /// If 2.8km is the linear distance, then 2.8 * 1.4 = 3.92km.
  /// If 2.8km is the actual road distance, then road factor should not be applied.
  ///
  /// Let's re-read: "Benchmark Trip: Fada Agbo Junction to Beach Junction (~2.8km) costs ₦500."
  /// If 2.8km is the distance input to `calculateFare` (already applying road factor or just straight from Geolocator?):
  /// "Convert to km and multiply by 1.4 (Road Factor)."
  /// If Geolocator says 2.8km, then road distance is 3.92.
  /// 200 + (3.92 * 110) = 631.2 -> 650.
  ///
  /// If 2.8km is the distance AFTER applying 1.4?
  /// 2.0 * 1.4 = 2.8.
  /// 200 + (2.8 * 110) = 200 + 308 = 508 -> 500.
  /// This matches the ₦500 mark perfectly!
  /// So the benchmark trip has a 2km linear distance, which becomes 2.8km road distance.
}
