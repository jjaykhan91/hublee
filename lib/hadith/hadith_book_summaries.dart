/// Brief descriptions for the well-known hadith books bundled in Hublee.
///
/// These are presentation copy for the Hadith tab, not grading. They cover
/// all 17 books: 3 Forties collections, 5 Other Books, and the 9 canonical
/// collections. Looked up once when the tab loads, not per tile rebuild.
library;

/// Returns a short description for [title] or [fileBaseName], or `null`
/// when the book is not one of the known collections.
String? hadithBookSummary({
  required String title,
  required String fileBaseName,
}) {
  final titleLower = title.toLowerCase().trim();
  final fileLower = fileBaseName.toLowerCase().trim();

  const nawawiSummary =
      'Concise foundations of Islam\u2014faith, worship, ethics, '
      'and sincerity. A beloved set of core principles often '
      'memorized and taught worldwide.';
  const qudsiSummary =
      'Forty sacred sayings in which the Prophet \uFDFA narrates '
      'the words of Allah outside the Quran\u2014highlighting '
      'divine mercy, love, justice, and guidance.';
  const waliullahSummary =
      'A practical revivalist selection by Shah Waliullah, '
      'balancing worship, morals, and social conduct\u2014aimed '
      'at everyday practice of the Sunnah.';
  const adabAlMufradSummary =
      'Imam al-Bukhari\u2019s dedicated compilation on Islamic '
      'manners, etiquette, and social conduct\u2014covering '
      'kindness to neighbours, parents, guests, and animals.';
  const bulughAlMaramSummary =
      'Ibn Hajar al-Asqalani\u2019s concise selection of hadiths '
      'used as legal evidence in Islamic jurisprudence (fiqh). '
      'Essential for students of Islamic law.';
  const mishkatSummary =
      'A comprehensive collection covering all aspects of Islamic '
      'life\u2014worship, transactions, manners, and spirituality '
      '\u2014with hadiths from multiple canonical sources.';
  const riyadSummary =
      'Imam Nawawi\u2019s selection of hadiths for righteous '
      'conduct, organised into chapters on sincerity, patience, '
      'truthfulness, and daily devotions.';
  const shamailSummary =
      'Imam al-Tirmidhi\u2019s renowned description of the '
      'Prophet\u2019s \uFDFA appearance, character, daily habits, '
      'worship, and personal qualities.';
  const bukhariSummary =
      'The most authentic hadith collection in Sunni Islam, '
      'compiled by Imam al-Bukhari with strict chains of '
      'narration. Covers worship, dealings, history, and virtues.';
  const muslimSummary =
      'The second most authentic collection, compiled by Imam '
      'Muslim. Known for its superior arrangement and grouping '
      'of similar narrations together.';
  const abuDawudSummary =
      'Imam Abu Dawud\u2019s collection focused primarily on '
      'hadiths of legal rulings (ahkam)\u2014covering purification, '
      'prayer, fasting, trade, and personal conduct.';
  const tirmidhiSummary =
      'Imam al-Tirmidhi\u2019s collection notable for including '
      'scholarly commentary and grading of each hadith. Covers '
      'faith, worship, virtues, and jurisprudence.';
  const nasaiSummary =
      'Imam al-Nasa\u2019i\u2019s rigorous collection focused on '
      'fiqh-related hadiths, with attention to narrators and '
      'precise chain verification.';
  const ibnMajahSummary =
      'Imam Ibn Majah\u2019s collection covering worship, business, '
      'asceticism, and virtues. Contains some unique hadiths not '
      'found in the other five canonical books.';
  const muwattaSummary =
      'The earliest compiled hadith book by Imam Malik, blending '
      'Prophetic traditions with the practice of the people of '
      'Madinah. Foundation of the Maliki school.';
  const musnadSummary =
      'One of the largest hadith compilations by Imam Ahmad ibn '
      'Hanbal, organised by narrator. An essential reference '
      'containing thousands of unique narrations.';
  const darimiSummary =
      'Imam al-Darimi\u2019s early collection known for its '
      'valuable introductory chapters on seeking knowledge, '
      'following the Sunnah, and Islamic methodology.';

  for (final key in [titleLower, fileLower]) {
    if (key.contains('nawawi') && !key.contains('riyad')) {
      return nawawiSummary;
    }
    if (key.contains('qudsi')) return qudsiSummary;
    if (key.contains('waliullah') ||
        key.contains('wali allah') ||
        key.contains('shah wali') ||
        key.contains('shahwali')) {
      return waliullahSummary;
    }
    if (key.contains('adab') && key.contains('mufrad')) {
      return adabAlMufradSummary;
    }
    if (key.contains('bulugh') || key.contains('maram')) {
      return bulughAlMaramSummary;
    }
    if (key.contains('mishkat') || key.contains('masabih')) {
      return mishkatSummary;
    }
    if (key.contains('riyad') || key.contains('salihin')) {
      return riyadSummary;
    }
    if (key.contains('shamail') || key.contains('muhammadiyah')) {
      return shamailSummary;
    }
    if (key.contains('bukhari') && !key.contains('adab')) {
      return bukhariSummary;
    }
    if (key.contains('muslim')) return muslimSummary;
    if (key.contains('abu') && key.contains('dawud')) return abuDawudSummary;
    if (key.contains('abudawud')) return abuDawudSummary;
    if (key.contains('tirmidhi')) return tirmidhiSummary;
    if (key.contains('nasa')) return nasaiSummary;
    if (key.contains('ibn') && key.contains('majah')) return ibnMajahSummary;
    if (key.contains('ibnmajah')) return ibnMajahSummary;
    if (key.contains('muwatta') || key.contains('malik')) {
      return muwattaSummary;
    }
    if (key.contains('musnad') ||
        key.contains('ahmad') ||
        key.contains('ahmed')) {
      return musnadSummary;
    }
    if (key.contains('darimi')) return darimiSummary;
  }

  return null;
}
