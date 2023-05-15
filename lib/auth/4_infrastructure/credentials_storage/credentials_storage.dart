import 'package:oauth2/oauth2.dart';

// ^ This will be inherited by both Local and Web storage child classes

abstract class CredentialsStorage {
  //  nullable because its possible the user is not authenticated
  Future<Credentials?> read();
  Future<void> save(Credentials credentials);
  Future<void> clear();
}
