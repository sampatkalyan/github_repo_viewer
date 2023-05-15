import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/auth/4_infrastructure/credentials_storage/credentials_storage.dart';

// ^ Saves, Reads and Clears Credentials object from cache and internal storage

class SecureCredentialsStorage implements CredentialsStorage {
  // This will be passed in by RiverPod, better than instantiating within the class
  SecureCredentialsStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _key = 'Oauth2_credentials';
  Credentials? _cachedCredentials;

  // This methods returns the cached variable if it exists, and reads storage if it doesn't. It
  // returns null if user is not signed in which is ok as its a nullable type
  @override
  Future<Credentials?> read() async {
    if (_cachedCredentials != null) {
      return _cachedCredentials;
    }
    final json = await _storage.read(key: _key);
    if (json == null) {
      return null;
    } else {
      try {
        return _cachedCredentials = Credentials.fromJson(json);
      } on FormatException {
        return null;
      }
    }
  }

  // This not only saves to storage but also a cached variable
  @override
  Future<void> save(Credentials credentials) {
    _cachedCredentials = credentials;
    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    _cachedCredentials = null;
    // _storage.delete satisfies the Future<void> return type
    return _storage.delete(key: _key);
  }
}
