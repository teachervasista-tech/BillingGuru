import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 password hashing.
///
/// Stored format: `pbkdf2-sha256$<iterations>$<salt b64>$<hash b64>`, so the
/// iteration count can be raised later without invalidating old hashes.
class PasswordHasher {
  const PasswordHasher({this.iterations = 60000});

  final int iterations;
  static const _keyLength = 32;
  static const _prefix = 'pbkdf2-sha256';

  String hash(String password) {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
    final derived = _pbkdf2(utf8.encode(password), salt, iterations);
    return [
      _prefix,
      '$iterations',
      base64Encode(salt),
      base64Encode(derived),
    ].join(r'$');
  }

  bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _prefix) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds <= 0) return false;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(password), salt, rounds);
    // Constant-time comparison.
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Uint8List _pbkdf2(List<int> password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, password);
    final output = Uint8List(_keyLength);
    var offset = 0;
    for (var block = 1; offset < _keyLength; block++) {
      final blockIndex = [
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < rounds; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      final take = min(t.length, _keyLength - offset);
      output.setRange(offset, offset + take, t);
      offset += take;
    }
    return output;
  }
}
