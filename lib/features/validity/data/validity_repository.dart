import '../domain/validity_model.dart';

/// Stub — substituir chamadas por RPC quando disponível.
/// Interface já preparada: fetchItems() retorna List<ValidityModel>.
class ValidityRepository {
  Future<List<ValidityModel>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockItems();
  }
}

List<ValidityModel> _mockItems() {
  final now = DateTime.now();
  return [
    ValidityModel(
      id: '1',
      productName: 'CHOCOLATADO PÓ NESCAU PACOTE 335G REFIL ECONÔMICO',
      brand: 'Nescau',
      barcode: '7891000353097',
      storeName: 'MART MINAS ALFENAS - LOJA 215',
      quantity: 420,
      quantityUnit: 'UN',
      priceAtc: 0.0,
      priceVrJr: 0.0,
      validityDate: now.add(const Duration(days: 3)),
    ),
    ValidityModel(
      id: '2',
      productName: 'ACHOCOLATADO PÓ NESCAU PACOTE 335G REFIL ECONÔMICO',
      brand: 'Nescau',
      barcode: '7891000353097',
      storeName: 'MART MINAS ALFENAS - LOJA 215',
      quantity: 469,
      quantityUnit: 'Caixa',
      priceAtc: 0.0,
      priceVrJr: 0.0,
      validityDate: now.add(const Duration(days: 44)),
    ),
    ValidityModel(
      id: '3',
      productName: 'REFRIG FANTA PET 2L LARANJA',
      brand: 'COCA COLA',
      barcode: '7894900031515',
      storeName: 'BH ESTACAO TRES CORACOES - LOJA 182',
      quantity: 625,
      quantityUnit: 'CX',
      priceAtc: 2.35,
      priceVrJr: 2.35,
      validityDate: now.add(const Duration(days: 47)),
    ),
    ValidityModel(
      id: '4',
      productName: 'ACHOC PO TODDY PT 800G ORIGINAL',
      brand: 'PEPSICO',
      barcode: '7896004004922',
      storeName: 'MART MINAS ALFENAS - LOJA 215',
      quantity: 271,
      quantityUnit: 'CX',
      priceAtc: 0.0,
      priceVrJr: 0.0,
      validityDate: now.add(const Duration(days: 170)),
    ),
    ValidityModel(
      id: '5',
      productName: 'ACHOCOLATADO PÓ NESCAU 400G',
      brand: 'Nescau',
      barcode: '7891000100103',
      storeName: 'MART MINAS ALFENAS - LOJA 215',
      quantity: 50,
      quantityUnit: 'UN',
      priceAtc: 4.50,
      priceVrJr: 4.50,
      validityDate: now.subtract(const Duration(days: 5)),
    ),
    ValidityModel(
      id: '6',
      productName: 'REFRIG COCA COLA PET 2L',
      brand: 'COCA COLA',
      barcode: '7894900011517',
      storeName: 'BH ESTACAO TRES CORACOES - LOJA 182',
      quantity: 12,
      quantityUnit: 'CX',
      priceAtc: 8.90,
      priceVrJr: 8.90,
      validityDate: now.add(const Duration(days: 90)),
      isAvaria: true,
    ),
  ];
}
