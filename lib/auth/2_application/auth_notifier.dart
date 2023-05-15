import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/auth/4_infrastructure/github_authenticator.dart';

import '../3_domain/auth_failure.dart';

part 'auth_notifier.freezed.dart';

// ^ Data Object which contains factory initializers which will be used to represent state.
@freezed
class AuthState with _$AuthState {
  const AuthState._();
  const factory AuthState.initial() = _Initial;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.authenticated() = _Authenticated;
  const factory AuthState.failure(AuthFailure failure) = _Failure;
}

typedef AuthUriCallback = Future<Uri> Function(Uri authorizationURL);

// ^ Orchestrates implementation of the infrastructure methods to provide a simpler interface for basic
// ^ authorisation requirements (SignIn, SignOut & SignedIn check).
// ^ Outputs one of the 4 possible AuthStates to trigger changes in the presentation layer

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authenticator) : super(const AuthState.initial());

  final GithubAuthenticator _authenticator;

  Future<void> checkAndUpdateAuthStatus() async {
    state = (await _authenticator.isSignedIn())
        ? const AuthState.authenticated()
        : const AuthState.unauthenticated();
  }

  // ! Note we are doing 2 things with this callback.
  // !   A) We are providing the authorizationURL are a parameter. This will direct the user to the site login page
  // !   B) We are specifying we want to receive a URI (the redirect) from that login screen once the user is authenticated
  // ! Have included the long version here but could use the TypeDef 'AuthUriCallback' we specified above for readability
  Future<void> signIn(
      Future<Uri> Function(Uri authorizationURL) authorizationCallback) async {
    final grant = _authenticator.createGrant();
    // ! We're calling the callback from within the function it seems
    final redirectUrl =
        await authorizationCallback(_authenticator.getAuthorizationUrl(grant));
    final failureOrSuccess = await _authenticator.handleAuthorizationResponse(
      grant,
      redirectUrl.queryParameters,
    );
    state = failureOrSuccess.fold(
      (l) => AuthState.failure(l),
      (r) => const AuthState.authenticated(),
    );
    grant.close();
  }

  Future<void> signOut() async {
    final failureOrSuccess = await _authenticator.signOut();
    state = failureOrSuccess.fold(
      (l) => AuthState.failure(l),
      (r) => const AuthState.unauthenticated(),
    );
  }
}
