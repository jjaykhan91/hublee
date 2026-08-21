/// Modern Standard Arabic grammar course pages.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../arabic/grammar_course.dart';
import '../router_paths.dart';
import '../theme/app_tokens.dart';
import 'widgets/arabic_text.dart';

class GrammarPage extends StatelessWidget {
  const GrammarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MSA grammar')),
      body: ListView.separated(
        padding: AppSpacing.list,
        itemCount: grammarCourse.length + 1,
        separatorBuilder: (_, index) =>
            index == 0 ? const SizedBox.shrink() : const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
              child: Text(
                'A short course in newspaper Arabic. Roots and verb forms '
                'first, then the grammar you meet in headlines.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          final lesson = grammarCourse[index - 1];
          return Card(
            child: ListTile(
              title: Text(lesson.title),
              subtitle: Text(lesson.subtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoute.grammarLesson(lesson.id)),
            ),
          );
        },
      ),
    );
  }
}

class GrammarLessonPage extends StatelessWidget {
  const GrammarLessonPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final lesson = grammarLessonById(lessonId);
    if (lesson == null) {
      return const Scaffold(body: Center(child: Text('Lesson not found')));
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(lesson.subtitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 16),
          for (final section in lesson.sections) ...[
            Text(
              section.heading,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            if (section.rows != null) ...[
              const SizedBox(height: 8),
              for (final row in section.rows!)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: ArabicText(
                    row.arabic,
                    tajweed: false,
                    fontSize: 22,
                    weight: FontWeight.w600,
                  ),
                  subtitle: Text(row.english),
                ),
            ],
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
