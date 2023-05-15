import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/auth/shared/providers.dart';
import 'package:repo_viewer/core/1_presentation/routes/app_router.gr.dart';
import 'package:repo_viewer/core/shared/providers.dart';
import '../../auth/2_application/auth_notifier.dart';

// ^ This provider performs the following setup operations
// ^ A) Instantiates local storage through sembast
// ^ B) Instantiates our dioProvider in a way where
// ^       - accept header is overwritten to always request data in our desired return format
// ^       - users auth key is used in all API requests
// ^       - token will automatically be refresh if possible and token has expired
// ^ C) Authorisation status is checked

final initializationProvider = FutureProvider((ref) async {
  await ref.read(sembastProvider).init();

  ref.read(dioProvider)
    ..options = BaseOptions(
      headers: {'Accept': 'application/vnd.github.html+json'},
      // this bit may not be necessary - seemed to be to fix a dio bug when tutorial was recorded
      validateStatus: (status) =>
          status != null && status >= 200 && status <= 400,
    )
    ..interceptors.add(ref.read(oAuth2InterceptorProvider));

  final authNotifier = ref.read(authNotifierProvider.notifier);
  await authNotifier.checkAndUpdateAuthStatus();
});

// ^ This class
// ^ A) Instantiates Router
// ^ B) Checks users authentication status
// ^ C) Directs them to the app or sign in page accordingly

class AppWidget extends ConsumerWidget {
  final appRouter = AppRouter();

  AppWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listening to this in the build method has the same effect of calling it within initState
    ref.listen(initializationProvider, (previous, next) {});
    // The 'AuthState' object has 4 variations as we defined with Freezed Unions (initial, unauthorized, authorized, failure)
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // MaybeMap allows us to provide logic for some of those scenarios
      next.maybeMap(
          authenticated: (_) {
            appRouter.pushAndPopUntil(
              const StarredReposRoute(),
              // The below will pop ALL previous screens. We don't want a backbutton which nvaigates back to the splash screen
              predicate: (route) => false,
            );
          },
          unauthenticated: (_) {
            appRouter.pushAndPopUntil(
              const SignInRoute(),
              // Similarly we dont want a user to be able to navigate back anywhere if he's signed out
              predicate: (route) => false,
            );
          },
          orElse: () {});
    });
    return MaterialApp.router(
      title: 'Repo Viewer',
      theme: _setUpThemeData(),
      routerDelegate: appRouter.delegate(),
      routeInformationParser: appRouter.defaultRouteParser(),
    );
  }

  ThemeData _setUpThemeData() {
    return ThemeData(
      appBarTheme: AppBarTheme(
          color: Colors.grey.shade50,
          titleTextStyle: const TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
          iconTheme: const IconThemeData(color: Colors.black)),
    );
  }
}
