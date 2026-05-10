import 'package:flutter/material.dart';
import 'package:campuschow/store/lib/features/dashboard/data/staff_member_model.dart';
import 'package:campuschow/store/lib/features/store/data/store_repository.dart';

class StaffProvider with ChangeNotifier {
  List<StaffMember> _staff = [];
  bool _isLoading = false;
  String? _error;

  List<StaffMember> get staff => _staff;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStaff(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _staff = await storeRepository.getStaff(storeId);
    } catch (e) {
      _error = 'Failed to load staff';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStaff(String storeId, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newStaff = await storeRepository.addStaff(storeId, email);
      _staff.add(newStaff);
    } catch (e) {
      _error = 'Failed to add staff. Ensure the user exists.';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeStaff(String storeId, String workerId) async {
    try {
      await storeRepository.removeStaff(storeId, workerId);
      _staff.removeWhere((s) => s.id == workerId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove staff';
      notifyListeners();
      throw Exception(_error);
    }
  }
}
