import 'dart:convert';
import 'package:dio/dio.dart';
import 'env.dart';

enum HeaderMode { bearer, xAuth }

class QfAuth {
  String? _token;
  DateTime? _exp;

  Future<String> token() async {
    if (_token != null && _exp != null && DateTime.now().isBefore(_exp!)) return _token!;
    final dio = Dio(BaseOptions(
      baseUrl: Env.oauthBase,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    final basic = base64Encode(utf8.encode('${Env.clientId}:${Env.clientSecret}'));
    final res = await dio.post(
      '/oauth2/token',
      data: 'grant_type=client_credentials&scope=${Env.scope}',
      options: Options(headers: {'Authorization': 'Basic $basic'}),
    );
    final data = res.data as Map;
    _token = data['access_token'] as String;
    final expiresIn = (data['expires_in'] ?? 3600) as int;
    _exp = DateTime.now().add(Duration(seconds: expiresIn - 30));
    return _token!;
  }
}

class QfContentConfig {
  final String baseUrl;   // e.g. https://apis-prelive.../content/api/v4
  final String prefix;    // '' or '/quran'
  final HeaderMode mode;  // bearer or xAuth
  QfContentConfig(this.baseUrl, this.prefix, this.mode);
}

class QfClient {
  final Dio _dio;
  final QfAuth _auth;
  QfContentConfig? _cfg;

  QfClient(this._dio, this._auth);

  QfContentConfig? get cfg => _cfg;

  Future<void> discover() async {
    final attempts = <String>[];

    final hosts = <String>[
      if (Env.contentHostOverride.isNotEmpty) Env.contentHostOverride,
      'https://apis-prelive.quran.foundation',
      'https://apis.quran.foundation',
    ];
    final paths = Env.contentPathCandidates;
    final prefixes = <String>['', '/quran']; // some envs put quran in the route, some in the base
    final token = await _auth.token();

    for (final host in hosts) {
      for (final path in paths) {
        for (final prefix in prefixes) {
          final base = '$host$path';
          final chapterPath = '$prefix/chapters';

          for (final mode in [HeaderMode.bearer, HeaderMode.xAuth]) {
            final url = '$base$chapterPath';
            attempts.add('GET $url  [headers: ${mode.name}]');
            try {
              final test = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 8)));
              test.interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
                if (mode == HeaderMode.bearer) {
                  o.headers['Authorization'] = 'Bearer $token';
                  o.headers['X-Client-Id'] = Env.clientId;
                } else {
                  o.headers['x-auth-token'] = token;
                  o.headers['x-client-id'] = Env.clientId;
                }
                h.next(o);
              }));
              final res = await test.get(chapterPath);
              if (res.statusCode == 200 && res.data is Map && (res.data['chapters'] != null)) {
                // lock config
                _cfg = QfContentConfig(base, prefix, mode);
                _dio.options.baseUrl = base;
                _dio.interceptors.clear();
                _dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
                  final tk = await _auth.token();
                  if (mode == HeaderMode.bearer) {
                    o.headers['Authorization'] = 'Bearer $tk';
                    o.headers['X-Client-Id'] = Env.clientId;
                  } else {
                    o.headers['x-auth-token'] = tk;
                    o.headers['x-client-id'] = Env.clientId;
                  }
                  h.next(o);
                }));
                _dio.interceptors.add(LogInterceptor(
                  request: true, requestHeader: true, responseHeader: false, responseBody: false,
                ));
                return;
              }
            } catch (e) {
              // keep trying, but log it once
              // ignore
            }
          }
        }
      }
    }

    // If we get here, discovery failed
    final msg = 'Quran Foundation discovery failed.\nTried:\n${attempts.join('\n')}';
    if (Env.fallbackToPublic) {
      // switch to Quran.com so the app works; we’ll still print what failed
      // (You’ll see this message in your logs.)
      // Configure Dio for public API:
      _dio.options.baseUrl = '${Env.publicBase}${Env.publicContent}';
      _dio.interceptors.clear();
      _dio.interceptors.add(LogInterceptor(
        request: true, requestHeader: false, responseHeader: false, responseBody: false,
      ));
      // Keep cfg null so we know we’re in public mode
      // Also print the attempts so you can share the exact URLs with me if needed.
      // ignore: avoid_print
      print(msg);
      return;
    } else {
      throw Exception(msg);
    }
  }

  bool get usingPublic => _cfg == null;
  Dio get dio => _dio;
}
