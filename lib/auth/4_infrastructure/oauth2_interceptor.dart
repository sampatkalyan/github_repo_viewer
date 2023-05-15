import 'package:dio/dio.dart';
import 'package:repo_viewer/auth/2_application/auth_notifier.dart';
import 'package:repo_viewer/auth/4_infrastructure/github_authenticator.dart';

// ^ A) adds the users access token to the header of all dio requests
// ^ B) on 401 errors
// ^        - Attempts to refresh users access token and repeat API request
// ^        - Calls refresh on auth status

class OAuth2Interceptor extends Interceptor {
  OAuth2Interceptor(this._authenticator, this._authNotifier, this._dio);

  final GithubAuthenticator _authenticator;
  final AuthNotifier _authNotifier;
  final Dio _dio;

  // We overide the default onRequest method to include the credentials taken from our authenticator
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final credentials = await _authenticator.getSignedInCredentials();
    final modifiedOptions = options
      ..headers.addAll(
        credentials == null
            ? {}
            : {'Authorization': 'bearer ${credentials.accessToken}'},
      );
    handler.next(modifiedOptions);
  }

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    final errorResponse = err.response;
    if (errorResponse != null && errorResponse.statusCode == 401) {
      final credentials = await _authenticator.getSignedInCredentials();
      credentials != null && credentials.canRefresh
          ? await _authenticator.refresh(credentials)
          : await _authenticator.clearCredentialsStorage();
      await _authNotifier.checkAndUpdateAuthStatus();

      // If credentials were refreshed try the call with the updated access token
      final refreshCredentials = await _authenticator.getSignedInCredentials();
      if (refreshCredentials != null) {
        handler.resolve(
          await _dio.fetch(
            errorResponse.requestOptions
              ..headers['Authorization'] =
                  'bearer ${refreshCredentials.accessToken}',
          ),
        );
      }
    } else {
      handler.next(err);
    }
  }
}
