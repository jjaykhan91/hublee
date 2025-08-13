import 'package:flutter/material.dart';
import '../data/local_arabic_repository.dart';
import '../data/local_translation_repository.dart';

class SurahDetailPage extends StatefulWidget {
  final int surahId;
  final String nameArabic;
  final String nameTranslit;
  final int versesCount;

  const SurahDetailPage({
    super.key,
    required this.surahId,
    required this.nameArabic,
    required this.nameTranslit,
    required this.versesCount,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  final _arRepo = LocalArabicRepository();
  final _trRepo = LocalTranslationRepository();

  late Future<List<_Row>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<_Row>> _load() async {
    final ar = await _arRepo.loadArabicForSurah(widget.surahId);
    final en = await _trRepo.loadClearQuranForSurah(widget.surahId);
    final rows = <_Row>[];
    for (var i = 1; i <= widget.versesCount; i++) {
      final k = '$i';
      rows.add(_Row(i, ar[k] ?? '', en[k] ?? ''));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.nameArabic} • ${widget.nameTranslit} • #${widget.surahId}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<_Row>>(
        future: _rows,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data ?? const <_Row>[];
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, i) {
              final r = rows[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            r.ar,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('Ayah ${r.n}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.en.isNotEmpty ? r.en : '— translation unavailable —',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Row {
  final int n;
  final String ar;
  final String en;
  _Row(this.n, this.ar, this.en);
}
