import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../repositories/business_repository.dart';
import '../repositories/expenses_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/sales_repository.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  AppState(SupabaseClient client)
      : auth = AuthService(client),
        businesses = BusinessRepository(client),
        inventory = InventoryRepository(client),
        sales = SalesRepository(client),
        expenses = ExpensesRepository(client);

  final AuthService auth;
  final BusinessRepository businesses;
  final InventoryRepository inventory;
  final SalesRepository sales;
  final ExpensesRepository expenses;

  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  Business? _business;
  bool _isBootstrapping = true;
  bool _isBusy = false;

  Session? get session => _session;
  User? get user => _session?.user;
  Business? get business => _business;
  bool get isAuthenticated => user != null;
  bool get isBootstrapping => _isBootstrapping;
  bool get isBusy => _isBusy;
  String get businessId => _business!.id;

  Future<void> bootstrap() async {
    _session = auth.currentSession;
    if (_session != null) {
      await _loadBusiness();
    }

    _authSubscription = auth.authStateChanges.listen((state) async {
      final oldUserId = _session?.user.id;
      final newUserId = state.session?.user.id;
      _session = state.session;
      if (oldUserId != newUserId) {
        _business = null;
        if (_session != null) {
          await _loadBusiness();
        }
      }
      notifyListeners();
    });

    _isBootstrapping = false;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _guard(() async {
      final response = await auth.signIn(email: email, password: password);
      _session = response.session;
      await _loadBusiness();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    var signedIn = false;
    await _guard(() async {
      final response = await auth.signUp(email: email, password: password);
      _session = response.session;
      signedIn = response.session != null;
      if (signedIn) {
        await _loadBusiness();
      }
    });
    return signedIn;
  }

  Future<void> createBusiness(String name) async {
    final currentUser = user;
    if (currentUser == null) return;
    await _guard(() async {
      _business = await businesses.create(ownerId: currentUser.id, name: name);
    });
  }

  Future<void> updateBusinessName(String name) async {
    final currentBusiness = business;
    if (currentBusiness == null) return;
    await _guard(() async {
      _business = await businesses.updateName(
        businessId: currentBusiness.id,
        name: name,
      );
    });
  }

  Future<void> signOut() async {
    await _guard(() async {
      await auth.signOut();
      _session = null;
      _business = null;
    });
  }

  Future<void> _loadBusiness() async {
    final currentUser = user;
    if (currentUser == null) {
      _business = null;
      return;
    }
    _business = await businesses.fetchForUser(currentUser.id);
  }

  Future<void> _guard(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
