enum EmergencyType {
  unsafe,
  injured,
  pickup,
}

extension EmergencyTypeExtension on EmergencyType {
  String get apiValue {
    switch (this) {
      case EmergencyType.unsafe:
        return "UNSAFE";
      case EmergencyType.injured:
        return "INJURED";
      case EmergencyType.pickup:
        return "PICKUP";
    }
  }
}