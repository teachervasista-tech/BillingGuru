import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const receiptBusinessDetailsAssetPath =
    'assets/config/receipt_business_details.txt';

final receiptBusinessDetailsProvider = FutureProvider<String>((ref) async {
  return (await rootBundle.loadString(receiptBusinessDetailsAssetPath)).trim();
});
