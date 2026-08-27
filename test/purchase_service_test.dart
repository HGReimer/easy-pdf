import 'package:easy_pdf/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Easy PDF Pro verwendet die feste Produkt-ID', () {
    expect(PurchaseService.productId, 'de.easyschmiede.easypdf.pro');
  });

  test('Linux bleibt für Entwicklung vollständig freigeschaltet', () async {
    final service = PurchaseService();

    expect(service.isLoading, isTrue);

    await service.initialize();

    expect(service.isLoading, isFalse);
    expect(service.isProUnlocked, isTrue);

    service.dispose();
  });
}
