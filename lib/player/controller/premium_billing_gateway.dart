import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

abstract class PremiumBillingGateway {
  ValueListenable<bool> get isPremiumListenable;

  Future<void> initialize();

  Future<void> purchasePremium();

  Future<void> restorePurchases();

  Future<void> debugSetPremium(bool premium);

  Future<void> dispose();
}

class MockPremiumBillingGateway implements PremiumBillingGateway {
  MockPremiumBillingGateway({required this.prefKey});

  final String prefKey;
  final ValueNotifier<bool> _isPremium = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get isPremiumListenable => _isPremium;

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium.value = prefs.getBool(prefKey) ?? false;
  }

  @override
  Future<void> purchasePremium() async {
    await debugSetPremium(true);
  }

  @override
  Future<void> restorePurchases() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium.value = prefs.getBool(prefKey) ?? false;
  }

  @override
  Future<void> debugSetPremium(bool premium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, premium);
    _isPremium.value = premium;
  }

  @override
  Future<void> dispose() async {
    _isPremium.dispose();
  }
}
