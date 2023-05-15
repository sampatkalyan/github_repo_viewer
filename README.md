# repo_viewer

A new Flutter project.

# build runner command
flutter pub run build_runner watch --delete-conflicting-outputs

## Workflow 


1 - SETUP
  A - Clean Yaml and add dependencies (see comments in .yaml)
  B - Add custom linting rules to analysis_options.yaml - Helps ensure we use immutable state etc..

2 - AUTH FEATURE
  A - Create an Oauth app on github
  B - Generate a personal access token for testing purposes
  C - Setup github.rest file

  D (Domain)
   - Create Freezed Union to cover AuthFail scenarios

  E (infrastructure)
    --> {GithubAuthenticator.dart} Purpose: Gets access token from Github and stores it in Credentials Object
        1 - Create field values necessary to manage authentication with reference to the Oath Github documentation: 
          * [clientID], 
          * [clientSecret], 
          * [scopes], 
          * [authorizationEndpoint], 
          * [tokenEndpoint], 
          * [revocationEndpoint], 
          * [redirectUrl],
        2 - Create following methods passing in the above fields
          * [getSignedInCredentials()] - Checks if user is signed in on app startup
          * [refresh()] - Refreshes token if expired. Not necessary if tokens never expire on given API
          * [isSignedIn()] - Facilitate signIn check throughout app
          * [createGrant()] - Creates  access licence (grant) which is passed to getAuthorization URL method
          * [getAuthorizationUrl()] - Provides url which will pass user to Github authentication screen
          * [handleAuthorizationResponse()] - On success, saves credentials to storage, on failure passes errors to 
          AuthFailure objects
          * [SignOut()] - Clears credentials from storage and deletes the accessKey from the API
        3 - Create [GithubOAuthHttpClient] class to facilitate communication with Oauth server so we receive JSON response (usually wont be necessary)
    --> {SectureCredentialsStorage.dart}
        4 - Create (SecureCredentialsStorage) class for local saving and caching - It should inmplement [read], [save] & [clear] methods inherited from an abstrat (CredentialsStorage) class which will also cover web scenarios

  F (application)
    --> {auth_notifier.dart}
        1 - Create an AuthState class. Use the freezed package to generate a data class with 4 constructors corresponding to the following states [Initial, Unauthorized, Authorized, Failure]
        2 - Crate an AuthNotifier class which extends StateNotifier. AuthState.initial should be instantiated in the constructor. Create the following methods utilizing the baser methods we created in the Infrastructure layer
        * [checkAndUpdatedAuthStatus] - Checks <isSignedIn> and returns AuthState.Authorized or AuthState.Unauthorized
        * [signIn] - Creates a grant <CreateGrant> uses it to <getAuthorisationURl>, passes that to <HandleAuthorisationResponse> returns AuthState.authenticated if success, AuthState.fail otherwise. Closes the grant
        * [signOut] - Calls <signOut>, returns AuthState.Unathenticated if success or AuthState.failure if not

  G (shared)
    --> {providers.dart}
        - Create the providers that connect our interdependant classes 
        [FlutterSecureStorageProvider] -> [CredentialsStorageProvider] 
        [DioProvider] & [CredentialsStorageProvider]  -> [gitHubAuthenticatorProvider] -> [AuthNotifierProvider]

  H (presentation)
        - Create empty pages for the following [SplashPage] (in its own feature), [SignInPage], [StarredReposPage]

3 - CORE 

  (presentation)
    --> {app_router.dart}
        - Setup MaterialAutoRouter (from the auto_router package) with our 3 pages. Define custom paths so they dont have 'page' in them and use the 'replaceInRouteName' parameter to replace the word 'Page' with 'Route'


4 - SPLASH

  (presentation)
    --> {splash_page.dart}
        - Create splash page

5 - CORE > Presentation

  (presentation)
    --> {app_widget.dart}
      - Create an FutureProvider for initialisation. It should read [AuthNotifierProvider] and call the [checkAndUpdateAuthStatus()] method. Call it with ref.listen in the build method to trigger it when the app starts up

  ON STARTUP 
  1) App is run <authNotifierProvider.AuthState.initial> user is routed to [SplashScreen]
  2) [checkAndUpdateAuthStatus()] is triggered from <initializationProvider>. This instantiates GithubAuthenticator and checks if the user [isSignedIn()]
  3) [isSignedIn()] calls [getSignedInCredentials()] which checks is Credentials are present in storage. 
    2A - If yes <authNotifierProvider.AuthState.authenticated> user is routed to [StarredRepos]
    2B - If yes but they have expired, it will call [refresh()] to renew the token then as above
    2C - Else <authNotifierProvider.AuthState.unauthenticated> user is routed to [SignInPage]

  ON LOGIN
  1) [signIn()] is triggered from <authNotifierProvider> with an authorizationCallback argument. The method calls infrastructure level methods from [GithubAuthenticator] to..
    [createGrant()]
    [createAuthorizationURL()] (from the callback, this is passed to the Github login webview screen)
    [handleAuthorizationResponse()]
      1A) If success 
        * Credentials saved to storage
        * <authNotifierProvider.AuthState.authenticated> user is routed to [StarredRepos]
      1B) If fail > <authNotifierProvider.AuthState.failure)

  ON SIGNOUT
  1) [signOut()] is triggered from <authNotifierProvider>
    * Token is revoked on Github site
    * Credentials are cleared
    if success <authNotifierProvider.AuthState.unauthenticated> user is routed to [SignInPage]
    If fail > <authNotifierProvider.AuthState.failure)

6 - EXPLORE API AND ESTABLISH FEATURE ARCHITECTURE
  A - Install REST extension so we can test API requests and confirm format of output
    1 - Generate an access token
    2 - Identify all activities required by the app. i.e, 
        * search repositories, 
        * show starred repositories, 
        * star a repository, 
        * unstar a repository 
        * etc... 
    3 - Identify and specify the required endpoints for each activity from the API documentation
    4 - Establish the media types we want to receive from the API and provide the appropriate query parameters in the accept headers (In this case want HTML which is appropriate for WebView)
    5 - Identify any features that are very similar in terms of both UI presentation and structure of the REST requests. These will be candidate subfeatures to group under a top level feature. In this case 'Starred Repos' and 'Repo Search' are very similar

7 - REPOS FEATURE

  A (DOMAIN)
    - Identify and create DataClasses. In this cases note both searched_repos and starred_repos screens contain identical tiles with the following info
      * repo name
      * repo description
      * owner avatar image
      * starred count
    Checking our REST API we can further see that an 'Owner' field is required for when we want to use certain endpoints. 
    - As we need 2 fields for an owner (name & avatar URL) we create a User data class (with freezed)
    [User] {
      * name
      * avatarUrl
    }
    - We can then create a GithubRepo dataclass with following fields 
    [GithubRepo] {
      * owner (above User class)
      * name
      * description
      * stargazerCount
    }
    - Finally a freezedUnion for failure scenarios
    [GithubFailure]
     * GithubFailure.api(int? errorCode) = _Api;
    
  B (INFRASTRUCTURE)
   - Create a corresponding DTO for each domain layer data class. Their purpose is to parse the json data we get from the server and return us a clean data class as defined in our application layer. We can copy the fields from the APPLICATION Data Classes and then use json_serializable to generate the 'fromJson' method we need. We just need to annotate in the correct json keys that correspond to our fields


        





    




