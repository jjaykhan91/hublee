import 'package:dio/dio.dart';
import '../../../core/env.dart';
import '../../../core/network_foundation.dart';

class QuranApi {
  final QfClient client;
  QuranApi(this.client);

  String get _p => client.cfg?.prefix ?? ''; // empty in public mode

  Future<Response<dynamic>> getChapters() => client.dio.get('$_p/chapters');

  Future<Response<dynamic>> getVersesByChapter(int chapter, {int perPage = 50, int page = 1}) {
    return client.dio.get(
      '$_p/verses/by_chapter/$chapter',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'translations': Env.clearQuranResId,
        'language': 'en',
      },
    );
  }

  Future<Response<dynamic>> getVersesByPage(int pageNumber) {
    return client.dio.get(
      '$_p/verses/by_page/$pageNumber',
      queryParameters: {
        'translations': Env.clearQuranResId,
        'language': 'en',
      },
    );
  }
}
