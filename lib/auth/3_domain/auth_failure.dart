import 'package:freezed_annotation/freezed_annotation.dart';
// Generate automatically with ptf snippet
part 'auth_failure.freezed.dart';

// 2d - When written this will show errors, you need to run the following command to generate the freezed file
// flutter pub run build_runner watch --delete-conflicting-outputs
// Note the freezed file itself is hidden from the tree under hidden items

@freezed
class AuthFailure with _$AuthFailure {
  const AuthFailure._();
  const factory AuthFailure.server([String? message]) = _Server;
  const factory AuthFailure.storage() = _Storage;
}
