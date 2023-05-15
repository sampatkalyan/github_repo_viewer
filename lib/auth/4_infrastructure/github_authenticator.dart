import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';
import 'package:repo_viewer/core/4_infrastructure/dio_extensions.dart';
import '../../core/shared/encoders.dart';
import '../3_domain/auth_failure.dart';
import 'credentials_storage/credentials_storage.dart';
import 'package:http/http.dart' as http;

// This class is only necessary because the gitHub api doesnt return json format by default
class GithubOAuthHttpClient extends http.BaseClient {
  final httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return httpClient.send(request);
  }
}

// ^ Contains fields and methods necessary to implement the Github Oauth authorisation process. Saves and clears
// ^ credentials to/from storage when user signs in or out
// ^ Contains:
// ^  Fields necessary to communicate with Github OAuth API
// ^  Methods to...
// ^    Check if user is logged in
// ^    Login and save credentials to storage
// ^    Logout and dispose of access token

class GithubAuthenticator {
  GithubAuthenticator(this._credentialsStorage, this._dio);

  // We instantiate the abstract class so we can use GithubAuthenticator with both Web and Local storage scenarios
  final CredentialsStorage _credentialsStorage;
  final Dio _dio;

  //static const clientId = '4239bd5cd051a1114d88';
  //static const clientSecret = 'a30681a3e9c03ddf0998cbcdb8132e8cf293c543';
  static const clientId = "5c337e895cfc51a4cf5c";
  static const clientSecret = "a62963e2a97e9e2b9868917504f2ca45bf53d52c";
  static const scopes = ['read:user', 'repo'];
  static final authorizationEndpoint =
      Uri.parse('https://github.com/login/oauth/authorize');
  static final tokenEndpoint =
      Uri.parse('https://github.com/login/oauth/access_token');
  static final revocationEndpoint =
      Uri.parse('https://api.github.com/applications/$clientId/token');
  static final redirectUrl = Uri.parse(
      'http://localhost:3000/callback'); // The Authorization callback URL we defined in our Oauth app on the Github website

  // ^ Methods that return signin status

  // Checks if user is signed in on startup
  Future<Credentials?> getSignedInCredentials() async {
    try {
      final storedCredentials = await _credentialsStorage.read();
      if (storedCredentials != null) {
        if (storedCredentials.canRefresh && storedCredentials.isExpired) {
          final failureOrCredentials = await refresh(storedCredentials);
          return failureOrCredentials.fold((l) => null, (r) => r);
        }
      }
      return storedCredentials;
    } on PlatformException {
      return null;
    }
  }

  // Refreshes access token if it has expired. Tokens do not expire on some API's so not always necessary
  Future<Either<AuthFailure, Credentials>> refresh(
      Credentials credentials) async {
    try {
      final refreshedCredentials = await credentials.refresh(
        identifier: clientId,
        secret: clientSecret,
        httpClient: GithubOAuthHttpClient(),
      );
      await _credentialsStorage.save(refreshedCredentials);
      return right(refreshedCredentials);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  // Returns signin status
  Future<bool> isSignedIn() =>
      getSignedInCredentials().then((credentials) => credentials != null);

  // ^ Methods that facilitate login

  // & NOTE: This grant contains the getAuthorizationUrl and handleAuthorizationResponse methods we use below
  AuthorizationCodeGrant createGrant() {
    return AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      secret: clientSecret,
      httpClient: GithubOAuthHttpClient(),
    );
  }

  // Provides url to which the user is directed to authorize themselves on gitHub along with the permissions they
  // will be granted. On success user is forwared to the redirect URL
  Uri getAuthorizationUrl(AuthorizationCodeGrant grant) {
    // we're just using the method attached to the grant itself
    return grant.getAuthorizationUrl(
      redirectUrl,
      scopes: scopes,
    );
  }

  // On success, saves credentials to storage, on failure passes errors to AuthFailure objects
  Future<Either<AuthFailure, Unit>> handleAuthorizationResponse(
    AuthorizationCodeGrant grant,
    Map<String, String> queryParams,
  ) async {
    try {
      final httpClient = await grant.handleAuthorizationResponse(queryParams);
      await _credentialsStorage.save(httpClient.credentials);
      return right(unit);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server('${e.error}: ${e.description}'));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  // ^ Methods that facilitate signOut

  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      final accessToken = await _credentialsStorage
          .read()
          .then((credentials) => credentials!.accessToken);
      final usernameAndPassword =
          stringToBase64.encode('$clientId:$clientSecret');
      // It's not strictly necessary to delete the old token, if you don't they'll just keep stacking up
      try {
        await _dio.deleteUri(revocationEndpoint,
            data: {'access_token': accessToken},
            options: Options(
              headers: {'Authorization': 'basic $usernameAndPassword'},
            ));
      } on DioError catch (e) {
        // We created this type manually as a dio extension - See core > infrastructure > dio_extensions.dart
        if (e.isNoConnectionError) {
          // ignoring
        } else {
          rethrow;
        }
      }
      return clearCredentialsStorage();
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Unit>> clearCredentialsStorage() async {
    try {
      await _credentialsStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }
}
