abstract class BarcodeScannerService {
  Future<String?> scan();
}

class ManualBarcodeScannerService implements BarcodeScannerService {
  @override
  Future<String?> scan() async {
    return null;
  }
}
