import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/auth/2_application/auth_notifier.dart';
import 'package:repo_viewer/auth/4_infrastructure/credentials_storage/credentials_storage.dart';
import 'package:repo_viewer/auth/4_infrastructure/credentials_storage/secure_credentials_storage.dart';
import 'package:repo_viewer/auth/4_infrastructure/github_authenticator.dart';
import 'package:repo_viewer/auth/4_infrastructure/oauth2_interceptor.dart';

// ^ This is the only one we call from the presentation layer, instantiating this will result in a chain reaction
// &^ of all providers below it in the dependency chain instantiating
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
    (ref) => AuthNotifier(ref.watch(githubAuthenticatorProvider)));

final githubAuthenticatorProvider = Provider(
  (ref) => GithubAuthenticator(
    ref.watch(credentialsStorageProvider),
    ref.watch(dioForAuthProvider),
  ),
);

// The type is our CredentialsStorage abstract class
final credentialsStorageProvider = Provider<CredentialsStorage>(
  (ref) => SecureCredentialsStorage(ref.watch(flutterSecureStorageProvider)),
);

final flutterSecureStorageProvider =
    Provider((ref) => const FlutterSecureStorage());

final oAuth2InterceptorProvider = Provider((ref) => OAuth2Interceptor(
      ref.watch(githubAuthenticatorProvider),
      ref.watch(authNotifierProvider.notifier),
      ref.watch(dioForAuthProvider),
    ));

// This does not contain the interceptor because of reasons
final dioForAuthProvider = Provider((ref) => Dio());
