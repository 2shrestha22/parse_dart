import 'dart:math' show pi, sin, cos, atan2, sqrt;

import 'package:equatable/equatable.dart';

/// Represents a geographical point with latitude and longitude
///
/// Used for geo queries in Parse.
///
/// Example:
/// ```dart
/// final location = ParseGeoPoint(37.7749, -122.4194); // San Francisco
/// object.set('location', location);
/// ```
class ParseGeoPoint extends Equatable {
  /// Latitude in degrees
  final double latitude;

  /// Longitude in degrees
  final double longitude;

  const ParseGeoPoint(this.latitude, this.longitude)
      : assert(latitude >= -90.0 && latitude <= 90.0,
            'Latitude must be within the range [-90.0, 90.0]'),
        assert(longitude >= -180.0 && longitude <= 180.0,
            'Longitude must be within the range [-180.0, 180.0]');

  /// Create from JSON
  factory ParseGeoPoint.fromJson(Map<String, dynamic> json) {
    return ParseGeoPoint(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '__type': 'GeoPoint',
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Calculate distance to another point in kilometers
  double distanceTo(ParseGeoPoint other) {
    const earthRadiusKm = 6371.0;

    final lat1 = _degToRad(latitude);
    final lat2 = _degToRad(other.latitude);
    final deltaLat = _degToRad(other.latitude - latitude);
    final deltaLon = _degToRad(other.longitude - longitude);

    final a = (sin(deltaLat / 2) * sin(deltaLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Calculate distance to another point in miles
  double distanceToInMiles(ParseGeoPoint other) {
    return distanceTo(other) * 0.621371;
  }

  double _degToRad(double degrees) {
    return degrees * (pi / 180.0);
  }

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() {
    return 'ParseGeoPoint(latitude: $latitude, longitude: $longitude)';
  }
}
