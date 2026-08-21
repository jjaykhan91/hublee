/// SM-2 review session for a deck (`msa` or `quran`).
library;

import 'package:flutter/material.dart';

import '../services/srs_scope.dart';
import '../services/srs_service.dart';
import '../theme/app_tokens.dart';
import 'widgets/arabic_text.dart';
import 'widgets/app_haptics.dart';

class SrsReviewPage extends StatefulWidget {
  const SrsReviewPage({super.key, this.deck = 'msa'});

  final String deck;

  @override
  State<SrsReviewPage> createState() => _SrsReviewPageState();
}

class _SrsReviewPageState extends State<SrsReviewPage> {
  SrsCard? _current;
  bool _revealed = false;
  var _sessionDone = 0;

  SrsCard? _nextDue() {
    final due = SrsScope.of(context).dueCards(deck: widget.deck);
    return due.isEmpty ? null : due.first;
  }

  Future<void> _rate(SrsRating rating) async {
    final card = _current;
    if (card == null) return;
    AppHaptics.selection();
    await SrsScope.of(context).review(card.id, rating);
    if (!mounted) return;
    setState(() {
      _sessionDone++;
      _revealed = false;
      _current = _nextDue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final srs = SrsScope.of(context);
    final remaining = srs.dueCount(deck: widget.deck);
    final card = _current ?? _nextDue();
    final quran = widget.deck == 'quran';

    return Scaffold(
      appBar: AppBar(title: Text(quran ? 'Quranic review' : 'MSA review')),
      body: Padding(
        padding: AppSpacing.page,
        child: card == null
            ? _CaughtUp(sessionDone: _sessionDone, quran: quran)
            : Column(
                children: [
                  Text(
                    '$remaining due · $_sessionDone done this session',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  Card(
                    child: InkWell(
                      onTap: () => setState(() => _revealed = true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 36,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              ArabicText(
                                card.arabic,
                                tajweed: false,
                                fontSize: 40,
                                weight: FontWeight.bold,
                                align: TextAlign.center,
                              ),
                              if (card.root != null) ...[
                                const SizedBox(height: 8),
                                Text('Root ${card.root}'),
                              ],
                              const SizedBox(height: 16),
                              if (_revealed)
                                Text(
                                  card.english,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                )
                              else
                                const Text('Tap to show the English'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!_revealed)
                    FilledButton(
                      onPressed: () => setState(() => _revealed = true),
                      child: const Text('Show meaning'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => _rate(SrsRating.again),
                          child: const Text('Again'),
                        ),
                        OutlinedButton(
                          onPressed: () => _rate(SrsRating.hard),
                          child: const Text('Hard'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => _rate(SrsRating.good),
                          child: const Text('Good'),
                        ),
                        FilledButton(
                          onPressed: () => _rate(SrsRating.easy),
                          child: const Text('Easy'),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp({required this.sessionDone, required this.quran});

  final int sessionDone;
  final bool quran;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        sessionDone == 0
            ? (quran
                  ? 'No Quranic cards due. Star words while reading, then review here.'
                  : 'No MSA cards due. Star words in the MSA dictionary first.')
            : 'Caught up. Come back tomorrow for the next SM-2 interval.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
