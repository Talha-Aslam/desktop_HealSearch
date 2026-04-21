import 'package:flutter/material.dart';

class TenantProvider extends ChangeNotifier {
  String? _pharmacyId;

  String? get pharmacyId => _pharmacyId;

  bool get isAuthenticated => _pharmacyId != null;

  void setPharmacyId(String id) {
    _pharmacyId = id;
    notifyListeners();
  }

  void clearTenant() {
    _pharmacyId = null;
    notifyListeners();
  }
}
