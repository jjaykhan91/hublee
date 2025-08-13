import 'package:flutter/material.dart';
import '../data/local_chapters_repository.dart';
import '../data/models.dart';
import 'surah_detail_page.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  final _repo = LocalChaptersRepository();
  final _searchCtrl = TextEditingController();

  List<Chapter> _all = [];
  List<Chapter> _filtered = [];
  late Future<void> _init;

  @override
  void initState() {
    super.initState();
    _init = _repo.loadChapters().then((chs) {
      _all = chs;
      _filtered = chs;
    });
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((c) =>
              c.nameSimple.toLowerCase().contains(q) ||
              c.nameArabic.contains(q) ||
              c.id.toString() == q).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hublee — Surahs')),
      body: FutureBuilder<void>(
        future: _init,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or number…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = _filtered[i];
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => SurahDetailPage(
                            surahId: c.id,
                            nameArabic: c.nameArabic,
                            nameTranslit: c.nameSimple,
                            versesCount: c.versesCount,
                          ),
                        ));
                      },
                      leading: CircleAvatar(child: Text('${c.id}')),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.nameSimple,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Flexible(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                c.nameArabic,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text('${c.revelationPlace} • ${c.versesCount} verses'),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
