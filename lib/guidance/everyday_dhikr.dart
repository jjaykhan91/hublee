/// Short dhikrs that may be said throughout the day, with sources.
///
/// Entries are Quran or well-known reports in Sahih al-Bukhari and
/// Sahih Muslim, or (where noted) Jami at-Tirmidhi / Hisn al-Muslim.
/// Virtue lines restate the cited report; they are not extra grading.
library;

import 'package:flutter/foundation.dart';

/// One everyday remembrance with Arabic, meaning, and a source.
@immutable
class EverydayDhikr {
  const EverydayDhikr({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.english,
    required this.source,
    this.virtue,
  });

  final String id;
  final String arabic;
  final String transliteration;
  final String english;
  final String source;
  final String? virtue;
}

/// Phrases a person can repeat at any time.
const List<EverydayDhikr> everydayDhikrCatalog = [
  EverydayDhikr(
    id: 'subhanallah',
    arabic: 'سُبْحَانَ اللَّهِ',
    transliteration: 'SubhanAllah',
    english: 'Glory be to Allah.',
    source: 'Sahih Muslim 2137',
    virtue:
        'Among the four phrases most beloved to Allah. The Prophet ﷺ '
        'said it does not matter which of them you begin with.',
  ),
  EverydayDhikr(
    id: 'alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Alhamdulillah',
    english: 'All praise is for Allah.',
    source: 'Sahih Muslim 2137',
    virtue:
        'Among the four phrases most beloved to Allah, with SubhanAllah, '
        'La ilaha illallah, and Allahu Akbar.',
  ),
  EverydayDhikr(
    id: 'tahlil',
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
    transliteration: 'La ilaha illallah',
    english: 'There is no god but Allah.',
    source: 'Sahih Muslim 2137',
    virtue:
        'Among the four phrases most beloved to Allah, with SubhanAllah, '
        'Alhamdulillah, and Allahu Akbar.',
  ),
  EverydayDhikr(
    id: 'allahu-akbar',
    arabic: 'اللَّهُ أَكْبَرُ',
    transliteration: 'Allahu Akbar',
    english: 'Allah is the Greatest.',
    source: 'Sahih Muslim 2137',
    virtue:
        'Among the four phrases most beloved to Allah. The Prophet ﷺ '
        'said it does not matter which of them you begin with.',
  ),
  EverydayDhikr(
    id: 'four-together',
    arabic:
        'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ '
        'وَلَا إِلَٰهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ',
    transliteration:
        'SubhanAllahi walhamdulillahi wa la ilaha illallahu wallahu akbar',
    english:
        'Glory be to Allah, all praise is for Allah, there is no god '
        'but Allah, and Allah is the Greatest.',
    source: 'Sahih Muslim 2137',
    virtue:
        'These four are the dearest of speech to Allah. You may begin '
        'with any of them.',
  ),
  EverydayDhikr(
    id: 'tasbih-hamd',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    transliteration: 'SubhanAllahi wa bihamdihi',
    english: 'Glory be to Allah, and praise is His.',
    source: 'Sahih al-Bukhari 6405; Sahih Muslim 2691',
    virtue:
        'Whoever says this one hundred times a day, his sins are forgiven '
        'even if they were like the foam of the sea.',
  ),
  EverydayDhikr(
    id: 'two-light-words',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    transliteration: 'SubhanAllahi wa bihamdihi, SubhanAllahil-Azeem',
    english:
        'Glory be to Allah, and praise is His. Glory be to Allah, the '
        'Most Great.',
    source: 'Sahih al-Bukhari 6682; Sahih Muslim 2694',
    virtue:
        'Two words that are light on the tongue, heavy on the Scale, and '
        'beloved to the Most Merciful.',
  ),
  EverydayDhikr(
    id: 'hawqala',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    transliteration: 'La hawla wa la quwwata illa billah',
    english: 'There is no power and no strength except with Allah.',
    source: 'Sahih al-Bukhari 6384; Sahih Muslim 2704',
    virtue: 'A treasure from the treasures of Paradise.',
  ),
  EverydayDhikr(
    id: 'istighfar',
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    transliteration: 'Astaghfirullah',
    english: 'I seek Allah\'s forgiveness.',
    source: 'Sahih al-Bukhari 6307',
    virtue:
        'The Prophet ﷺ said he sought forgiveness from Allah and turned '
        'to Him more than seventy times a day.',
  ),
  EverydayDhikr(
    id: 'istighfar-tawbah',
    arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    transliteration: 'Astaghfirullaha wa atubu ilayh',
    english: 'I seek Allah\'s forgiveness and I repent to Him.',
    source: 'Sahih al-Bukhari 6307; Sahih Muslim 2702',
    virtue:
        'The Prophet ﷺ combined seeking forgiveness with turning back to '
        'Allah, more than seventy times a day (Bukhari), and in another '
        'wording a hundred times a day (Muslim).',
  ),
  EverydayDhikr(
    id: 'tahlil-wahdahu',
    arabic:
        'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، '
        'لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
    transliteration:
        'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa '
        'lahul-hamdu wa huwa ala kulli shay\'in qadir',
    english:
        'There is no god but Allah, alone, with no partner. His is the '
        'dominion and His is the praise, and He is over all things capable.',
    source: 'Sahih al-Bukhari 6403; Sahih Muslim 2691',
    virtue:
        'Whoever says this one hundred times a day has the reward of '
        'freeing ten slaves, a hundred good deeds written, a hundred '
        'sins erased, and protection from Shaytan that day.',
  ),
  EverydayDhikr(
    id: 'ya-hayyu-ya-qayyum',
    arabic: 'يَا حَيُّ يَا قَيُّومُ',
    transliteration: 'Ya Hayyu Ya Qayyum',
    english: 'O Ever-Living, O Self-Sustaining Sustainer.',
    source: 'Quran 2:255; 3:2',
    virtue:
        'Allah names Himself Al-Hayy and Al-Qayyum in Ayat al-Kursi and '
        'at the opening of Ali Imran.',
  ),
  EverydayDhikr(
    id: 'ya-hayyu-astaghith',
    arabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
    transliteration: 'Ya Hayyu Ya Qayyum, bi-rahmatika astaghith',
    english: 'O Ever-Living, O Self-Sustaining, by Your mercy I seek help.',
    source: 'Jami at-Tirmidhi 3524; Hisn al-Muslim',
    virtue:
        'Whenever a matter distressed him, the Prophet ﷺ would say this. '
        'This report is not in the two Sahihs.',
  ),
  EverydayDhikr(
    id: 'ya-dhal-jalali',
    arabic: 'يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    transliteration: 'Ya Dhal-Jalali wal-Ikram',
    english: 'O Possessor of Majesty and Honour.',
    source: 'Jami at-Tirmidhi 3524',
    virtue:
        'The Prophet ﷺ said: be constant with this. This report is not '
        'in the two Sahihs.',
  ),
  EverydayDhikr(
    id: 'hasbunallah',
    arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    transliteration: 'Hasbunallahu wa ni\'mal-wakeel',
    english:
        'Allah is sufficient for us, and He is the best Disposer of '
        'affairs.',
    source: 'Quran 3:173; Sahih al-Bukhari 4563',
    virtue:
        'Ibrahim ﷺ said this when he was thrown into the fire, and the '
        'Prophet ﷺ and his companions said it when people gathered '
        'against them.',
  ),
  EverydayDhikr(
    id: 'yunus',
    arabic:
        'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    transliteration: 'La ilaha illa anta, subhanaka, inni kuntu minaz-zalimin',
    english:
        'There is no god but You. Glory be to You. I have been among '
        'the wrongdoers.',
    source: 'Quran 21:87; Jami at-Tirmidhi 3505',
    virtue:
        'The call of Yunus ﷺ in the belly of the whale. A report in '
        'Jami at-Tirmidhi says no Muslim supplicates with it except that '
        'Allah responds. That report is not in the two Sahihs.',
  ),
  EverydayDhikr(
    id: 'salawat',
    arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
    transliteration: 'Allahumma salli ala Muhammad',
    english: 'O Allah, send Your blessings upon Muhammad ﷺ.',
    source: 'Sahih Muslim 408',
    virtue:
        'Whoever sends one blessing upon the Prophet ﷺ, Allah sends '
        'ten blessings upon him.',
  ),
  EverydayDhikr(
    id: 'heavy-tasbih',
    arabic:
        'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ وَرِضَا نَفْسِهِ '
        'وَزِنَةَ عَرْشِهِ وَمِدَادَ كَلِمَاتِهِ',
    transliteration:
        'SubhanAllahi wa bihamdihi, adada khalqihi, wa rida nafsihi, '
        'wa zinata arshihi, wa midada kalimatihi',
    english:
        'Glory be to Allah and praise is His, as many times as the number '
        'of His creatures, according to His pleasure, equal to the weight '
        'of His Throne, and to the ink of His words.',
    source: 'Sahih Muslim 2726',
    virtue:
        'The Prophet ﷺ taught Juwairiyah this, saying it three times '
        'outweighed a long morning of dhikr.',
  ),
];
