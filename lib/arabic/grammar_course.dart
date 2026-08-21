/// Original Modern Standard Arabic grammar course for Hublee.
///
/// These lessons are Hublee's own teaching notes, not a reprint of a
/// copyrighted textbook. Verb Forms I–X follow the classical paradigm
/// taught in Wright (public domain, 1896).
library;

import 'package:flutter/foundation.dart';

@immutable
class GrammarLesson {
  const GrammarLesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<GrammarSection> sections;
}

@immutable
class GrammarSection {
  const GrammarSection({required this.heading, required this.body, this.rows});

  final String heading;
  final String body;
  final List<GrammarRow>? rows;
}

@immutable
class GrammarRow {
  const GrammarRow({required this.arabic, required this.english});

  final String arabic;
  final String english;
}

/// Ordered MSA course. Separate from Quranic word-by-word study.
const grammarCourse = <GrammarLesson>[
  GrammarLesson(
    id: 'roots',
    title: 'Roots (الجذر)',
    subtitle: 'Most Arabic words grow from three consonants',
    sections: [
      GrammarSection(
        heading: 'The idea',
        body:
            'Newspaper Arabic, like Quranic Arabic, is built on roots. '
            'A root is usually three letters that carry a core meaning. '
            'Patterns around those letters make verbs, nouns, and adjectives. '
            'Learn the root, and a family of words opens at once.',
      ),
      GrammarSection(
        heading: 'كتب — writing',
        body:
            'The root ك ت ب is about writing. Different patterns around '
            'those three letters give everyday newspaper words.',
        rows: [
          GrammarRow(arabic: 'كَتَبَ', english: 'he wrote (Form I verb)'),
          GrammarRow(arabic: 'يَكْتُبُ', english: 'he writes'),
          GrammarRow(arabic: 'كِتَاب', english: 'book'),
          GrammarRow(arabic: 'كَاتِب', english: 'writer'),
          GrammarRow(arabic: 'مَكْتَب', english: 'office, desk'),
          GrammarRow(arabic: 'مَكْتَبَة', english: 'library, bookstore'),
          GrammarRow(arabic: 'كِتَابَة', english: 'writing'),
        ],
      ),
      GrammarSection(
        heading: 'How Hublee shows roots',
        body:
            'The Modern Arabic dictionary lists a root when Wiktionary '
            'or the core list has one. Star the word and the root stays '
            'on the study card.',
      ),
    ],
  ),
  GrammarLesson(
    id: 'forms',
    title: 'Verb forms I–X',
    subtitle: 'Morphology: the ten common patterns newspapers use',
    sections: [
      GrammarSection(
        heading: 'Why forms matter',
        body:
            'Arabic verbs are numbered I to X in Western teaching. '
            'Each form is a pattern that tweaks the root meaning — '
            'causative, reflexive, intensive, and so on. Headlines '
            'are full of Forms II, IV, V, VIII, and X.',
      ),
      GrammarSection(
        heading: 'The ten forms (root ف ع ل)',
        body: 'Past-tense skeleton. Vowels vary by verb; this is the map.',
        rows: [
          GrammarRow(arabic: 'I  فَعَلَ', english: 'basic meaning'),
          GrammarRow(arabic: 'II  فَعَّلَ', english: 'intensive / causative'),
          GrammarRow(arabic: 'III  فَاعَلَ', english: 'with someone (effort)'),
          GrammarRow(arabic: 'IV  أَفْعَلَ', english: 'causative'),
          GrammarRow(arabic: 'V  تَفَعَّلَ', english: 'reflexive of II'),
          GrammarRow(arabic: 'VI  تَفَاعَلَ', english: 'reciprocal of III'),
          GrammarRow(
            arabic: 'VII  اِنْفَعَلَ',
            english: 'passive / intransitive',
          ),
          GrammarRow(arabic: 'VIII  اِفْتَعَلَ', english: 'reflexive / middle'),
          GrammarRow(arabic: 'IX  اِفْعَلَّ', english: 'colors and defects'),
          GrammarRow(
            arabic: 'X  اِسْتَفْعَلَ',
            english: 'seek, consider, request',
          ),
        ],
      ),
      GrammarSection(
        heading: 'Newspaper examples',
        body: 'Same root, different form — different headline.',
        rows: [
          GrammarRow(arabic: 'عَلِمَ', english: 'I — he knew'),
          GrammarRow(arabic: 'عَلَّمَ', english: 'II — he taught'),
          GrammarRow(arabic: 'أَعْلَمَ', english: 'IV — he informed'),
          GrammarRow(arabic: 'تَعَلَّمَ', english: 'V — he learned'),
          GrammarRow(arabic: 'اِسْتَعْلَمَ', english: 'X — he inquired'),
          GrammarRow(arabic: 'قَرَّرَ', english: 'II — he decided'),
          GrammarRow(arabic: 'اِجْتَمَعَ', english: 'VIII — he met'),
          GrammarRow(arabic: 'اِنْتَخَبَ', english: 'VIII — he elected'),
          GrammarRow(arabic: 'أَعْلَنَ', english: 'IV — he announced'),
        ],
      ),
    ],
  ),
  GrammarLesson(
    id: 'alphabet',
    title: 'The alphabet',
    subtitle: '28 letters, joined in a word',
    sections: [
      GrammarSection(
        heading: 'Joining',
        body:
            'Arabic is written right to left. Most letters change shape '
            'depending on whether they sit alone, at the start, middle, '
            'or end of a word. Six letters never join to what follows: '
            'ا د ذ ر ز و.',
      ),
      GrammarSection(
        heading: 'Short vowels',
        body:
            'Newspapers usually drop tashkeel (َ ِ ُ). You infer the '
            'vowels from the root, the pattern, and context — which is '
            'why roots and forms are worth learning first. Hublee keeps '
            'vowels on dictionary headwords when the source has them.',
      ),
    ],
  ),
  GrammarLesson(
    id: 'article',
    title: 'The definite article',
    subtitle: 'ال — sun and moon letters',
    sections: [
      GrammarSection(
        heading: 'ال',
        body:
            'ال makes a noun definite: كتاب a book → الكتاب the book. '
            'It is written on the word, not as a separate article like English "the".',
      ),
      GrammarSection(
        heading: 'Sun letters (الحروف الشمسية)',
        body:
            'Before a sun letter, the ل of ال is not pronounced. The next '
            'letter is doubled (shadda): الشمس ash-shams, not al-shams. '
            'Sun letters include ت ث د ذ ر ز س ش ص ض ط ظ ل ن.',
      ),
      GrammarSection(
        heading: 'Moon letters (الحروف القمرية)',
        body:
            'Before a moon letter, ل is pronounced: القمر al-qamar, '
            'الكتاب al-kitāb. Moon letters include the rest of the alphabet, '
            'such as ا ب ج ح خ ع غ ف ق ك م ه و ي.',
      ),
    ],
  ),
  GrammarLesson(
    id: 'pronouns',
    title: 'Pronouns and “to be”',
    subtitle: 'Independent pronouns; no present-tense is/are',
    sections: [
      GrammarSection(
        heading: 'Independent pronouns',
        body: 'Used as the subject, or for emphasis.',
        rows: [
          GrammarRow(arabic: 'أَنَا', english: 'I'),
          GrammarRow(arabic: 'أَنْتَ / أَنْتِ', english: 'you (m. / f.)'),
          GrammarRow(arabic: 'هُوَ / هِيَ', english: 'he / she'),
          GrammarRow(arabic: 'نَحْنُ', english: 'we'),
          GrammarRow(
            arabic: 'أَنْتُمْ / أَنْتُنَّ',
            english: 'you (m. pl. / f. pl.)',
          ),
          GrammarRow(arabic: 'هُمْ / هُنَّ', english: 'they (m. / f.)'),
        ],
      ),
      GrammarSection(
        heading: 'Equational sentences',
        body:
            'MSA has no present-tense verb “to be”. أنت طالب means '
            '"you [are] a student." Past and future use كان / سيكون. '
            'Negation of a present nominal sentence often uses ليس.',
        rows: [
          GrammarRow(arabic: 'هُوَ صَحَفِيٌّ', english: 'He is a journalist'),
          GrammarRow(arabic: 'لَيْسَ مُهِمًّا', english: 'It is not important'),
        ],
      ),
    ],
  ),
  GrammarLesson(
    id: 'gender',
    title: 'Gender and number',
    subtitle: 'Masculine, feminine; dual; sound and broken plurals',
    sections: [
      GrammarSection(
        heading: 'Feminine ة',
        body:
            'Many feminine nouns and adjectives end in ة (tāʾ marbūṭa): '
            'مدينة city, جديدة new (f.). Adjectives agree with the noun '
            'in gender, number, and definiteness: مدينة كبيرة، المدينة الكبيرة.',
      ),
      GrammarSection(
        heading: 'Dual and plural',
        body:
            'Dual adds انِ / يْنِ (two). Sound masculine plural is ونَ / ينَ. '
            'Sound feminine plural is ات. Many nouns instead use a broken '
            'plural (internal pattern): كتاب → كُتُب, رجل → رِجَال. '
            'Newspapers expect you to recognise common broken plurals.',
      ),
    ],
  ),
  GrammarLesson(
    id: 'idafa',
    title: 'Iḍāfa (possession)',
    subtitle: 'Noun + noun, no “of” word required',
    sections: [
      GrammarSection(
        heading: 'The construct',
        body:
            'وزير الخارجية is “the minister of foreign affairs.” '
            'The first noun drops tanwīn and, if feminine, often shows '
            'the ت of ة. Only the last noun takes ال when the whole '
            'phrase is definite.',
        rows: [
          GrammarRow(
            arabic: 'كِتَابُ الطَّالِبِ',
            english: 'the student’s book',
          ),
          GrammarRow(
            arabic: 'وَزِيرُ الْخَارِجِيَّةِ',
            english: 'the foreign minister',
          ),
          GrammarRow(
            arabic: 'مُؤْتَمَرُ الصَّحَافَةِ',
            english: 'the press conference',
          ),
        ],
      ),
    ],
  ),
  GrammarLesson(
    id: 'past',
    title: 'The past tense',
    subtitle: 'Suffixed conjugation — headlines love it',
    sections: [
      GrammarSection(
        heading: 'Form I past of كتب',
        body: 'Suffixes mark the subject. This is the usual narrative tense.',
        rows: [
          GrammarRow(arabic: 'كَتَبْتُ', english: 'I wrote'),
          GrammarRow(
            arabic: 'كَتَبْتَ / كَتَبْتِ',
            english: 'you wrote (m. / f.)',
          ),
          GrammarRow(arabic: 'كَتَبَ / كَتَبَتْ', english: 'he / she wrote'),
          GrammarRow(arabic: 'كَتَبْنَا', english: 'we wrote'),
          GrammarRow(
            arabic: 'كَتَبُوا / كَتَبْنَ',
            english: 'they wrote (m. / f.)',
          ),
        ],
      ),
    ],
  ),
  GrammarLesson(
    id: 'present',
    title: 'The present tense',
    subtitle: 'Prefixed conjugation — news and commentary',
    sections: [
      GrammarSection(
        heading: 'Form I present of كتب',
        body:
            'A prefix (and sometimes a suffix) marks the subject. '
            'The same shape covers present and future; future is often '
            'marked with سـ or سوف.',
        rows: [
          GrammarRow(arabic: 'أَكْتُبُ', english: 'I write'),
          GrammarRow(
            arabic: 'تَكْتُبُ / تَكْتُبِينَ',
            english: 'you write (m. / f.)',
          ),
          GrammarRow(
            arabic: 'يَكْتُبُ / تَكْتُبُ',
            english: 'he writes / she writes',
          ),
          GrammarRow(arabic: 'نَكْتُبُ', english: 'we write'),
          GrammarRow(arabic: 'سَيَكْتُبُ', english: 'he will write'),
        ],
      ),
    ],
  ),
  GrammarLesson(
    id: 'questions',
    title: 'Questions and negation',
    subtitle: 'هل، ما، لم، لن — reading a denial in a headline',
    sections: [
      GrammarSection(
        heading: 'Asking',
        body:
            'هل opens a yes/no question. ما / ماذا what, من who, '
            'أين where, متى when, كيف how, لماذا why, كم how many.',
      ),
      GrammarSection(
        heading: 'Negation',
        body:
            'لا + present ≈ does not. ما + past ≈ did not (also لم + jussive). '
            'لن + present ≈ will not. ليس negates a nominal sentence. '
            'لا still means “no” on its own.',
        rows: [
          GrammarRow(arabic: 'هَلْ وَافَقَ؟', english: 'Did he agree?'),
          GrammarRow(arabic: 'لَا يَعْرِفُ', english: 'he does not know'),
          GrammarRow(arabic: 'لَمْ يَقُلْ', english: 'he did not say'),
          GrammarRow(arabic: 'لَنْ يَحْضُرَ', english: 'he will not attend'),
        ],
      ),
    ],
  ),
];

GrammarLesson? grammarLessonById(String id) {
  for (final lesson in grammarCourse) {
    if (lesson.id == id) return lesson;
  }
  return null;
}
