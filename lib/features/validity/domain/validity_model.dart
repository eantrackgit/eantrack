import 'package:flutter/foundation.dart';

@immutable
class ValidityModel {
  const ValidityModel({
    required this.id,
    required this.productName,
    required this.brand,
    required this.barcode,
    required this.storeName,
    required this.quantity,
    required this.quantityUnit,
    required this.priceAtc,
    required this.priceVrJr,
    required this.validityDate,
    this.imageUrl,
    this.isAvaria = false,
  });

  final String id;
  final String productName;
  final String brand;
  final String barcode;
  final String storeName;
  final int quantity;
  final String quantityUnit;
  final double priceAtc;
  final double priceVrJr;
  final DateTime validityDate;
  final String? imageUrl;
  final bool isAvaria;

  int get daysRemaining {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final validDate = DateTime(
      validityDate.year,
      validityDate.month,
      validityDate.day,
    );
    return validDate.difference(todayDate).inDays;
  }

  bool get isExpired => daysRemaining < 0;
}
