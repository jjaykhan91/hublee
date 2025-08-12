import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network_foundation.dart';
import 'data/quran_api.dart';
import 'data/quran_repository.dart';

// Auth + HTTP
final _authProvider = Provider((_) => QfAuth());
final _dioProvider  = Provider((_) => Dio());

// Discover & build QF client
final clientProvider = FutureProvider<QfClient>((ref) async {
  final client = QfClient(ref.read(_dioProvider), ref.read(_authProvider));
  await client.discover();
  return client;
});

// API + Repo (wait on client)
final apiProvider = FutureProvider<QuranApi>((ref) async {
  final client = await ref.watch(clientProvider.future);
  return QuranApi(client);
});

final repoProvider = FutureProvider<QuranRepository>((ref) async {
  final api = await ref.watch(apiProvider.future);
  return QuranRepository(api);
});
