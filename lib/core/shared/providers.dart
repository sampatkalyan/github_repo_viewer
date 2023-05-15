import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repo_viewer/core/4_infrastructure/sembast_database.dart';

final sembastProvider = Provider((ref) => SembastDatabase());

// This is instantiated with custom BaseOptions from the initialization provider
// ? Could i not just instantiate it here for clarity?
final dioProvider = Provider((ref) => Dio());
