import 'package:auto_route/annotations.dart';
import 'package:repo_viewer/auth/1_presentation/sign_in_page.dart';
import 'package:repo_viewer/splash/1_presentation/splash_page.dart';
import '../../../auth/1_presentation/authorization_page.dart';
import '../../../github/detail/1_presentation/repo_detail_page.dart';
import '../../../github/repos/searched_repos/1_presentation/searched_repos_page.dart';
import '../../../github/repos/starred_repos/1_presentation/starred_repos_page.dart';

@MaterialAutoRouter(
  routes: [
    MaterialRoute(page: SplashPage, initial: true),
    MaterialRoute(page: SignInPage, path: '/sign-in'),
    MaterialRoute(page: AuthorizationPage, path: '/auth'),
    MaterialRoute(page: StarredReposPage, path: '/starred'),
    MaterialRoute(page: SearchedReposPage, path: '/search'),
    MaterialRoute(page: RepoDetailPage, path: '/detail'),
  ],
  replaceInRouteName: 'Page,Route',
)
class $AppRouter {}
