/// Practical salah outline: the five fard, sunnah/rawatib, nawafil,
/// how to pray, and what to recite.
///
/// This is not a fatwa. Where schools differ, the copy says so.
/// Recitation sources are Quran or well-known reports; Tirmidhi
/// items are labelled and not called sahih on their own.
library;

import 'package:flutter/foundation.dart';

/// Fard, confirmed sunnah around the fard, or extra voluntary prayer.
enum SalahKind { fard, sunnah, nafl }

/// Hub section ids used by [AppRoute.salahSection].
abstract final class SalahSectionId {
  SalahSectionId._();

  static const fard = 'fard';
  static const sunnah = 'sunnah';
  static const nawafil = 'nawafil';
  static const howTo = 'how-to';
  static const recite = 'recite';
}

/// One of the five daily prayers, a rawatib sunnah, or a nafl prayer.
@immutable
class SalahPrayer {
  const SalahPrayer({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.kind,
    required this.rakahsLabel,
    required this.when,
    required this.how,
    this.note,
  });

  final String id;
  final String arabicName;
  final String englishName;
  final SalahKind kind;

  /// e.g. `2 fard rak'ahs`.
  final String rakahsLabel;
  final String when;
  final String how;
  final String? note;
}

/// A phrase recited in salah, with source.
@immutable
class SalahRecitation {
  const SalahRecitation({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.english,
    required this.source,
    this.note,
  });

  final String id;
  final String title;
  final String arabic;
  final String transliteration;
  final String english;
  final String source;
  final String? note;
}

/// One action in the rak'ah sequence.
@immutable
class SalahStep {
  const SalahStep({required this.title, required this.body, this.recitationId});

  final String title;
  final String body;

  /// Optional id in [salahRecitations].
  final String? recitationId;
}

/// Hub tile for the salah page.
@immutable
class SalahHubTile {
  const SalahHubTile({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

/// Looks up a recitation by [id], or `null` if it is missing.
SalahRecitation? salahRecitationById(String id) {
  for (final recitation in salahRecitations) {
    if (recitation.id == id) return recitation;
  }
  return null;
}

/// Opening copy on the salah hub.
const List<String> salahIntroParagraphs = [
  'Salah is the five daily prayers — standing, bowing, and '
      'prostrating before Allah at the times He appointed. The '
      'Prophet ﷺ said: “Pray as you have seen me praying.” '
      '(Sahih al-Bukhari 631)',
  'This is a practical outline of the fard (obligatory) prayers, '
      'the confirmed sunnah around them, extra nawafil, the rak‘ah '
      'sequence, and what to recite. It is not a fatwa. Schools of '
      'law differ on some details — where the hands rest, whether '
      'to recite aloud behind an imam, qunut. Follow a teacher you '
      'trust.',
  'You must have wudu (Quran 5:6), face the qibla, cover as required, '
      'and pray after the time has entered. Hublee does not compute '
      'prayer times; use a local timetable.',
];

const String salahSourceNote =
    'Fard rak‘ah counts and the obligation of Al-Fatiha are from '
    'the two Sahihs. The twelve rawatib rak‘ahs are in Sahih Muslim '
    '728; which prayer they sit around is listed in Jami at-Tirmidhi '
    '414. Opening du‘a, extra surahs, and many tasbihat are sunnah, '
    'not pillars.';

/// Hub navigation.
const List<SalahHubTile> salahHubTiles = [
  SalahHubTile(
    id: SalahSectionId.fard,
    title: 'The five daily prayers',
    subtitle: 'Fard rak‘ahs, loud or silent, and Jumu‘ah',
  ),
  SalahHubTile(
    id: SalahSectionId.sunnah,
    title: 'Sunnah around the fard',
    subtitle: 'The twelve rawatib rak‘ahs, then Witr',
  ),
  SalahHubTile(
    id: SalahSectionId.nawafil,
    title: 'Nawafil (extra prayers)',
    subtitle: 'Duha, tahajjud, greeting the mosque, and more',
  ),
  SalahHubTile(
    id: SalahSectionId.howTo,
    title: 'How to pray',
    subtitle: 'Each step of a rak‘ah, then 2, 3, and 4 rak‘ahs',
  ),
  SalahHubTile(
    id: SalahSectionId.recite,
    title: 'What to recite',
    subtitle: 'Takbir, Al-Fatiha, ruku, sujud, tashahhud, taslim',
  ),
];

/// The five fard prayers plus Jumu‘ah.
const List<SalahPrayer> salahFardPrayers = [
  SalahPrayer(
    id: 'fajr',
    arabicName: 'الْفَجْر',
    englishName: 'Fajr',
    kind: SalahKind.fard,
    rakahsLabel: '2 fard rak‘ahs',
    when: 'From true dawn until sunrise.',
    how:
        'Two rak‘ahs, recited aloud. After Al-Fatiha, recite another '
        'surah in both rak‘ahs. Sit for tashahhud after the second, '
        'then taslim. Two sunnah rak‘ahs before the fard are strongly '
        'emphasised.',
  ),
  SalahPrayer(
    id: 'dhuhr',
    arabicName: 'الظُّهْر',
    englishName: 'Dhuhr',
    kind: SalahKind.fard,
    rakahsLabel: '4 fard rak‘ahs',
    when: 'After the sun passes its zenith, until Asr.',
    how:
        'Four rak‘ahs, recited silently. First tashahhud after two '
        'rak‘ahs, then stand for the third and fourth. A further surah '
        'after Al-Fatiha is sunnah in the first two rak‘ahs. On Friday, '
        'Jumu‘ah in congregation replaces Dhuhr.',
  ),
  SalahPrayer(
    id: 'asr',
    arabicName: 'الْعَصْر',
    englishName: 'Asr',
    kind: SalahKind.fard,
    rakahsLabel: '4 fard rak‘ahs',
    when: 'After Dhuhr’s time ends, until Maghrib.',
    how:
        'Four rak‘ahs, recited silently, in the same pattern as Dhuhr. '
        'The twelve confirmed rawatib do not include a sunnah before '
        'Asr; extra rak‘ahs then are nawafil.',
  ),
  SalahPrayer(
    id: 'maghrib',
    arabicName: 'الْمَغْرِب',
    englishName: 'Maghrib',
    kind: SalahKind.fard,
    rakahsLabel: '3 fard rak‘ahs',
    when: 'From sunset until the red twilight fades (Isha).',
    how:
        'Three rak‘ahs. The first two are recited aloud, the third '
        'silently. Sit after two, stand for the third (Al-Fatiha), sit '
        'for the final tashahhud, then taslim. Two sunnah rak‘ahs after '
        'the fard are among the twelve rawatib.',
  ),
  SalahPrayer(
    id: 'isha',
    arabicName: 'الْعِشَاء',
    englishName: 'Isha',
    kind: SalahKind.fard,
    rakahsLabel: '4 fard rak‘ahs',
    when: 'After Maghrib’s twilight, until Fajr (best earlier in the night).',
    how:
        'Four rak‘ahs. The first two are recited aloud, the last two '
        'silently, in the same pattern as Dhuhr. Two sunnah rak‘ahs after '
        'the fard are among the twelve. Witr follows Isha.',
  ),
  SalahPrayer(
    id: 'jumuah',
    arabicName: 'الْجُمُعَة',
    englishName: 'Jumu‘ah (Friday)',
    kind: SalahKind.fard,
    rakahsLabel: '2 fard rak‘ahs in congregation',
    when: 'In place of Dhuhr on Friday, after the khutbah.',
    how:
        'Two rak‘ahs recited aloud behind the imam, after the sermon. '
        'This replaces Dhuhr that day for those who pray it in '
        'congregation. If it is missed, Dhuhr is prayed instead.',
    note: 'Hublee does not list a local khutbah time. Follow your mosque.',
  ),
];

/// Confirmed sunnah around the five, plus Witr.
const List<SalahPrayer> salahSunnahPrayers = [
  SalahPrayer(
    id: 'sunnah-fajr',
    arabicName: 'سُنَّةُ الْفَجْر',
    englishName: 'Before Fajr',
    kind: SalahKind.sunnah,
    rakahsLabel: '2 rak‘ahs',
    when: 'After Fajr’s time enters, before the fard.',
    how:
        'Two light rak‘ahs. The Prophet ﷺ did not leave them, travelling '
        'or at home.',
    note: 'Among the twelve rawatib (Jami at-Tirmidhi 414).',
  ),
  SalahPrayer(
    id: 'sunnah-dhuhr-before',
    arabicName: 'سُنَّةُ الظُّهْرِ قَبْلَهَا',
    englishName: 'Before Dhuhr',
    kind: SalahKind.sunnah,
    rakahsLabel: '4 rak‘ahs',
    when: 'After Dhuhr’s time enters, before the fard.',
    how: 'Four rak‘ahs, often prayed as two sets of two.',
    note: 'Among the twelve rawatib (Jami at-Tirmidhi 414).',
  ),
  SalahPrayer(
    id: 'sunnah-dhuhr-after',
    arabicName: 'سُنَّةُ الظُّهْرِ بَعْدَهَا',
    englishName: 'After Dhuhr',
    kind: SalahKind.sunnah,
    rakahsLabel: '2 rak‘ahs',
    when: 'After the fard of Dhuhr.',
    how: 'Two rak‘ahs.',
    note: 'Among the twelve rawatib (Jami at-Tirmidhi 414).',
  ),
  SalahPrayer(
    id: 'sunnah-maghrib',
    arabicName: 'سُنَّةُ الْمَغْرِب',
    englishName: 'After Maghrib',
    kind: SalahKind.sunnah,
    rakahsLabel: '2 rak‘ahs',
    when: 'After the fard of Maghrib.',
    how: 'Two rak‘ahs.',
    note: 'Among the twelve rawatib (Jami at-Tirmidhi 414).',
  ),
  SalahPrayer(
    id: 'sunnah-isha',
    arabicName: 'سُنَّةُ الْعِشَاء',
    englishName: 'After Isha',
    kind: SalahKind.sunnah,
    rakahsLabel: '2 rak‘ahs',
    when: 'After the fard of Isha, before Witr.',
    how: 'Two rak‘ahs.',
    note: 'Among the twelve rawatib (Jami at-Tirmidhi 414).',
  ),
  SalahPrayer(
    id: 'witr',
    arabicName: 'الْوِتْر',
    englishName: 'Witr',
    kind: SalahKind.sunnah,
    rakahsLabel: 'An odd number — often 1 or 3 rak‘ahs',
    when: 'After Isha, last prayer of the night if you pray tahajjud.',
    how:
        'Pray an odd number of rak‘ahs after Isha. Many pray three: two '
        'with taslim, then one; or three together with one taslim. Some '
        'schools recite qunut in Witr. Follow what you have been taught.',
    note:
        'Make your last prayer of the night witr. '
        '(Sahih al-Bukhari 998; Sahih Muslim 751)',
  ),
];

/// Extra voluntary prayers — a short list, not exhaustive fiqh.
const List<SalahPrayer> salahNaflPrayers = [
  SalahPrayer(
    id: 'duha',
    arabicName: 'صَلَاةُ الضُّحَى',
    englishName: 'Duha (forenoon)',
    kind: SalahKind.nafl,
    rakahsLabel: 'At least 2 rak‘ahs',
    when: 'After the sun has risen until just before Dhuhr.',
    how:
        'Two or more rak‘ahs in pairs. The Prophet ﷺ recommended the '
        'forenoon prayer. (Sahih Muslim 748, 720)',
  ),
  SalahPrayer(
    id: 'tahajjud',
    arabicName: 'التَّهَجُّد',
    englishName: 'Tahajjud (night prayer)',
    kind: SalahKind.nafl,
    rakahsLabel: 'In pairs, as many as you are able',
    when: 'After Isha, best in the last third of the night.',
    how:
        'Pray two by two. If you will pray tahajjud, delay Witr until '
        'you finish. Allah praises those who leave their beds to call '
        'on Him. (Quran 32:16; 17:79)',
  ),
  SalahPrayer(
    id: 'tahiyyat',
    arabicName: 'تَحِيَّةُ الْمَسْجِد',
    englishName: 'Greeting the mosque',
    kind: SalahKind.nafl,
    rakahsLabel: '2 rak‘ahs',
    when: 'When you enter a mosque, before sitting.',
    how:
        'Two rak‘ahs. The Prophet ﷺ said: when one of you enters the '
        'mosque, he should not sit until he has prayed two rak‘ahs. '
        '(Sahih al-Bukhari 444; Sahih Muslim 714)',
  ),
  SalahPrayer(
    id: 'wudu-prayer',
    arabicName: 'سُنَّةُ الْوُضُوء',
    englishName: 'After wudu',
    kind: SalahKind.nafl,
    rakahsLabel: '2 rak‘ahs',
    when: 'After completing wudu, before the water dries if you wish.',
    how:
        'Two rak‘ahs. Bilal رضي الله عنه said this was the deed he '
        'hoped in most; the Prophet ﷺ heard his footsteps in Paradise. '
        '(Sahih al-Bukhari 1149; Sahih Muslim 2458)',
  ),
  SalahPrayer(
    id: 'istikhara',
    arabicName: 'صَلَاةُ الِاسْتِخَارَة',
    englishName: 'Istikhara',
    kind: SalahKind.nafl,
    rakahsLabel: '2 rak‘ahs, then the du‘a',
    when: 'When you need to choose a permitted matter.',
    how:
        'Pray two rak‘ahs, then ask Allah to choose what is better. The '
        'wording is in Sahih al-Bukhari 1166. Hublee’s du‘a list includes '
        'istikhara among the sunnah du‘as.',
  ),
];

/// Sequence of one rak‘ah, then how longer prayers differ.
const List<SalahStep> salahHowToSteps = [
  SalahStep(
    title: 'Before you stand',
    body:
        'Have wudu. Face the qibla. Cover as required. Make sure the '
        'time has entered. Form the intention in your heart for this '
        'prayer — you do not need to say a formula out loud.',
  ),
  SalahStep(
    title: 'Takbirat al-ihram',
    body:
        'Raise the hands and say Allahu Akbar. This opens the prayer. '
        'From here until taslim, do not speak ordinary speech.',
    recitationId: 'takbir',
  ),
  SalahStep(
    title: 'Opening (sunnah)',
    body:
        'Place the hands on the chest or below it, as you have been '
        'taught. It is sunnah to say an opening du‘a quietly, then to '
        'seek refuge from Shaytan, then to begin recitation.',
    recitationId: 'istiftah',
  ),
  SalahStep(
    title: 'Al-Fatiha',
    body:
        'Recite Al-Fatiha in every rak‘ah. The Prophet ﷺ said there is '
        'no salah for the one who does not recite the Opening of the '
        'Book. (Sahih Muslim 394; Sahih al-Bukhari 756). Then, in the '
        'first two rak‘ahs, recite another surah or some ayahs. A short '
        'surah such as Al-Ikhlas is often learned first — any Quran '
        'you know is enough.',
  ),
  SalahStep(
    title: 'Ruku‘ (bowing)',
    body:
        'Say Allahu Akbar and bow, back level, hands on the knees. '
        'Glorify your Lord in the bow. Rise saying Sami‘Allahu liman '
        'hamidah, then Rabbana wa lakal-hamd while standing.',
    recitationId: 'ruku',
  ),
  SalahStep(
    title: 'Sujud (prostration)',
    body:
        'Say Allahu Akbar and go down: forehead, nose, palms, knees, '
        'and toes on the ground, facing the qibla. Glorify your Lord '
        'in the prostration. Sit briefly, ask forgiveness, then a '
        'second sujud.',
    recitationId: 'sujud',
  ),
  SalahStep(
    title: 'Between the two sujuds',
    body: 'Sit calmly and ask Allah to forgive you, then go down again.',
    recitationId: 'jalsa',
  ),
  SalahStep(
    title: 'The second rak‘ah',
    body:
        'Stand with Allahu Akbar. Recite Al-Fatiha (and another surah '
        'in the first two rak‘ahs), then ruku‘ and the two sujuds as '
        'before.',
  ),
  SalahStep(
    title: 'Tashahhud',
    body:
        'After the second rak‘ah (and at the end of the prayer), sit '
        'and recite the tashahhud, then the salawat upon the Prophet ﷺ. '
        'You may add a du‘a before taslim.',
    recitationId: 'tashahhud',
  ),
  SalahStep(
    title: 'Taslim',
    body:
        'Turn the head to the right, then the left, saying the greeting '
        'of peace each time. This ends the prayer.',
    recitationId: 'taslim',
  ),
  SalahStep(
    title: 'Two, three, and four rak‘ahs',
    body:
        'Two rak‘ahs (Fajr, many sunnah and nafl): after the second '
        'sujud of rak‘ah two, sit for the final tashahhud and taslim.\n\n'
        'Three rak‘ahs (Maghrib, often Witr): after two rak‘ahs sit for '
        'the first tashahhud (without taslim), stand for the third, '
        'recite Al-Fatiha, complete ruku‘ and sujud, then the final '
        'tashahhud and taslim.\n\n'
        'Four rak‘ahs (Dhuhr, Asr, Isha): same as three, then a fourth '
        'rak‘ah like the third, then the final tashahhud and taslim. '
        'A surah after Al-Fatiha is sunnah in the first two rak‘ahs; '
        'the later rak‘ahs are Al-Fatiha, then ruku‘.',
  ),
  SalahStep(
    title: 'Loud and silent',
    body:
        'Fajr is recited aloud. The first two rak‘ahs of Maghrib and '
        'Isha are recited aloud; the rest of those prayers are silent. '
        'Dhuhr and Asr are silent. Behind an imam, follow him; schools '
        'differ on reciting Al-Fatiha when he recites aloud.',
  ),
];

/// Phrases recited in salah. Al-Fatiha is loaded from Quran assets.
const List<SalahRecitation> salahRecitations = [
  SalahRecitation(
    id: 'takbir',
    title: 'Takbir',
    arabic: 'اللَّهُ أَكْبَرُ',
    transliteration: 'Allahu Akbar',
    english: 'Allah is the Greatest.',
    source: 'Sahih al-Bukhari 631; opening of every movement in salah',
  ),
  SalahRecitation(
    id: 'istiftah',
    title: 'Opening du‘a (sunnah)',
    arabic:
        'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، '
        'وَتَعَالَىٰ جَدُّكَ، وَلَا إِلَٰهَ غَيْرُكَ',
    transliteration:
        'Subhanakallahumma wa bihamdika, wa tabarakasmuka, wa ta‘ala '
        'jadduka, wa la ilaha ghayruk',
    english:
        'Glory be to You, O Allah, and praise. Blessed is Your name, '
        'exalted is Your majesty, and there is no god but You.',
    source: 'Sahih al-Bukhari 744; Sahih Muslim 399',
    note: 'Sunnah after the opening takbir, said quietly.',
  ),
  SalahRecitation(
    id: 'istiadha',
    title: 'Seeking refuge',
    arabic: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
    transliteration: 'A‘udhu billahi minash-shaytanir-rajim',
    english: 'I seek refuge with Allah from the accursed Shaytan.',
    source: 'Quran 16:98',
    note: 'Before reciting Quran, including at the start of salah.',
  ),
  SalahRecitation(
    id: 'ruku',
    title: 'In ruku‘',
    arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
    transliteration: 'Subhana Rabbiyal-‘Azeem',
    english: 'Glory be to my Lord, the Most Great.',
    source: 'Sahih Muslim 772',
    note: 'Said in the bow, often three times. Not a pillar of wording.',
  ),
  SalahRecitation(
    id: 'sami',
    title: 'Rising from ruku‘',
    arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ',
    transliteration: 'Sami‘Allahu liman hamidah',
    english: 'Allah hears the one who praises Him.',
    source: 'Sahih al-Bukhari 789',
  ),
  SalahRecitation(
    id: 'hamd',
    title: 'Standing after ruku‘',
    arabic: 'رَبَّنَا وَلَكَ الْحَمْدُ',
    transliteration: 'Rabbana wa lakal-hamd',
    english: 'Our Lord, and to You is the praise.',
    source: 'Sahih al-Bukhari 789',
  ),
  SalahRecitation(
    id: 'sujud',
    title: 'In sujud',
    arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
    transliteration: 'Subhana Rabbiyal-A‘la',
    english: 'Glory be to my Lord, the Most High.',
    source: 'Sahih Muslim 772',
    note: 'Said in each prostration, often three times.',
  ),
  SalahRecitation(
    id: 'jalsa',
    title: 'Between the two sujuds',
    arabic: 'رَبِّ اغْفِرْ لِي',
    transliteration: 'Rabbighfir li',
    english: 'My Lord, forgive me.',
    source: 'Sunan Ibn Majah 897; Sunan Abi Dawud 874',
    note:
        'This wording is not in the two Sahihs. Sitting calmly between '
        'the sujuds is established; the exact phrase varies by school.',
  ),
  SalahRecitation(
    id: 'tashahhud',
    title: 'Tashahhud',
    arabic:
        'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، '
        'السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ '
        'وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللَّهِ '
        'الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ '
        'وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
    transliteration:
        'At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu '
        '‘alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. '
        'As-salamu ‘alayna wa ‘ala ‘ibadillahis-salihin. Ashhadu an '
        'la ilaha illallahu wa ashhadu anna Muhammadan ‘abduhu wa rasuluh',
    english:
        'All greetings, prayers, and good things are for Allah. Peace '
        'be upon you, O Prophet, and the mercy of Allah and His '
        'blessings. Peace be upon us and upon the righteous servants of '
        'Allah. I bear witness that there is no god but Allah, and I '
        'bear witness that Muhammad is His servant and messenger.',
    source: 'Sahih al-Bukhari 831; Sahih Muslim 402',
    note: 'The tashahhud of Ibn Mas‘ud رضي الله عنه.',
  ),
  SalahRecitation(
    id: 'salawat',
    title: 'Salawat (after tashahhud)',
    arabic:
        'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ، '
        'كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، '
        'إِنَّكَ حَمِيدٌ مَجِيدٌ. اللَّهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ '
        'وَعَلَىٰ آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ '
        'وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
    transliteration:
        'Allahumma salli ‘ala Muhammadin wa ‘ala ali Muhammad, kama '
        'sallayta ‘ala Ibrahima wa ‘ala ali Ibrahim, innaka hamidun '
        'majid. Allahumma barik ‘ala Muhammadin wa ‘ala ali Muhammad, '
        'kama barakta ‘ala Ibrahima wa ‘ala ali Ibrahim, innaka hamidun '
        'majid',
    english:
        'O Allah, send blessings upon Muhammad and the family of '
        'Muhammad, as You sent blessings upon Ibrahim and the family of '
        'Ibrahim. You are Praiseworthy, Glorious. O Allah, bless '
        'Muhammad and the family of Muhammad, as You blessed Ibrahim '
        'and the family of Ibrahim. You are Praiseworthy, Glorious.',
    source: 'Sahih al-Bukhari 3370; Sahih Muslim 406',
  ),
  SalahRecitation(
    id: 'taslim',
    title: 'Taslim',
    arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
    transliteration: 'As-salamu ‘alaykum wa rahmatullah',
    english: 'Peace be upon you, and the mercy of Allah.',
    source: 'Sahih Muslim 582',
    note: 'Said to the right, then to the left, to leave the prayer.',
  ),
];
