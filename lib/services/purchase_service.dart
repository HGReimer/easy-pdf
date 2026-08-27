import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService extends ChangeNotifier {
  static const String productId = 'de.easyschmiede.easypdf.pro';
  static const String _proPreferenceKey = 'easy_pdf_pro_unlocked';
  static const bool _simulateFreeMode = bool.fromEnvironment(
    'EASY_PDF_SIMULATE_FREE',
  );

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _proProduct;

  bool _isProUnlocked = false;
  bool _storeAvailable = false;
  bool _isLoading = true;
  bool _purchasePending = false;
  String? _errorMessage;

  bool get usesAppleStore => Platform.isIOS;

  // Unter Linux bleibt die vollständige App für Entwicklung und Tests frei.
  bool get isProUnlocked =>
      (!usesAppleStore && !_simulateFreeMode) || _isProUnlocked;

  bool get storeAvailable => _storeAvailable;
  bool get isLoading => _isLoading;
  bool get purchasePending => _purchasePending;
  String? get errorMessage => _errorMessage;
  String? get proPrice => _proProduct?.price;

  Future<void> initialize() async {
    if (!usesAppleStore) {
      _isProUnlocked = !_simulateFreeMode;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      _isProUnlocked = preferences.getBool(_proPreferenceKey) ?? false;

      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (Object error) {
          _errorMessage = 'Kaufstatus konnte nicht geladen werden: $error';
          _purchasePending = false;
          notifyListeners();
        },
      );

      _storeAvailable = await _inAppPurchase.isAvailable();

      if (_storeAvailable) {
        final response = await _inAppPurchase.queryProductDetails(
          const <String>{productId},
        );

        if (response.productDetails.isNotEmpty) {
          _proProduct = response.productDetails.first;
        } else if (response.error != null) {
          _errorMessage = response.error!.message;
        } else {
          _errorMessage = 'Easy PDF Pro ist im App Store noch nicht verfügbar.';
        }
      } else {
        _errorMessage = 'Der App Store ist derzeit nicht erreichbar.';
      }
    } catch (error) {
      _errorMessage = 'Der Kaufdienst konnte nicht gestartet werden: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buyPro() async {
    final product = _proProduct;

    if (!_storeAvailable || product == null || _purchasePending) {
      return;
    }

    _purchasePending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

      if (!started) {
        _purchasePending = false;
        _errorMessage = 'Der Kauf konnte nicht gestartet werden.';
        notifyListeners();
      }
    } catch (error) {
      _purchasePending = false;
      _errorMessage = 'Der Kauf konnte nicht gestartet werden: $error';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable || _purchasePending) {
      return;
    }

    _purchasePending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
    } catch (error) {
      _errorMessage = 'Käufe konnten nicht wiederhergestellt werden: $error';
    } finally {
      _purchasePending = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _unlockPro();
          _purchasePending = false;

        case PurchaseStatus.error:
          _errorMessage =
              purchase.error?.message ??
              'Beim Kauf ist ein Fehler aufgetreten.';
          _purchasePending = false;

        case PurchaseStatus.canceled:
          _purchasePending = false;
      }

      if (purchase.pendingCompletePurchase &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }

    notifyListeners();
  }

  Future<void> _unlockPro() async {
    _isProUnlocked = true;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_proPreferenceKey, true);
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
