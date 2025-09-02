import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../hadith/hadith_repository.dart';
import '../hadith/models.dart';
import 'widgets/arabic_text.dart';

class HadithBookPage extends StatefulWidget {
  final String collectionId;
  final String bookFile;
  final String title;
  final int? scrollToIndex; // 0-based

  const HadithBookPage({
    super.key,
    required this.collectionId,
    required this.bookFile,
    required this.title,
    this.scrollToIndex,
  });

  @override
  State<HadithBookPage> createState() => _HadithBookPageState();
}

class _HadithBookPageState extends State<HadithBookPage> {
  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();

  @override
  Widget build(BuildContext context) {
    final repo = const HadithRepository();

    return FutureBuilder<HadithBook>(
      future: repo.loadBook(widget.collectionId, widget.bookFile),
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final error = snap.hasError ? snap.error.toString() : null;
        final book = snap.data;

        return Scaffold(
          appBar: AppBar(title: Text(book?.title ?? widget.title)),
          body: () {
            if (loading) return const Center(child: CircularProgressIndicator());
            if (error != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: $error\n\nTried: assets/hadith/${widget.collectionId}/${widget.bookFile}',
                ),
              );
            }

            final items = book!.hadiths;

            // Jump exactly to the requested item after first frame
            if (widget.scrollToIndex != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final idx = widget.scrollToIndex!.clamp(0, items.length - 1);
                if (_scroll.isAttached) {
                  // instant jump (no lag), then a tiny smooth align
                  _scroll.jumpTo(index: idx);
                  _scroll.scrollTo(
                    index: idx,
                    duration: const Duration(milliseconds: 200),
                    alignment: 0.08,
                    curve: Curves.easeInOut,
                  );
                }
              });
            }

            return ScrollablePositionedList.separated(
              itemScrollController: _scroll,
              itemPositionsListener: _positions,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final h = items[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Hadith ${i + 1}${h.idInBook != null ? ' • #${h.idInBook}' : ''}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (h.narrator?.isNotEmpty == true)
                          Text(h.narrator!, style: Theme.of(context).textTheme.labelMedium),
                        if (h.narrator?.isNotEmpty == true) const SizedBox(height: 6),
                        if (h.arabic?.isNotEmpty == true)
                          ArabicText(h.arabic!, fontSize: 18, weight: FontWeight.w600),
                        if (h.arabic?.isNotEmpty == true) const SizedBox(height: 8),
                        if (h.english?.isNotEmpty == true)
                          Text(h.english!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            );
          }(),
        );
      },
    );
  }
}
