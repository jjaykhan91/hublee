# Fonts

- **KFGQPCQuranicFontHafsSmart_08.ttf** – Quranic Arabic (PUA glyphs). Used for ayah text and fallback surah names.
- **surah-name-v4.ttf** – [Tarteel QUL Surah name font v4](https://qul.tarteel.ai/resources/font/457). Ligature-based: `surah001`–`surah114` render calligraphic Arabic surah names. Used in the reader header when the title is on the Arabic step.
- **qpc_v4_tajweed/** – [QPC V4 Tajweed font](https://qul.tarteel.ai/resources/font/240) (page-by-page, p1.ttf–p604.ttf). The app uses only V4 for tajweed. Download via: `dart run tools/download_v4_tajweed.dart`. You also need the [V4 Glyphs script JSON](https://qul.tarteel.ai/resources/quran-script/47) saved as `assets/quran/qpc-v4.json`. If the QUL link doesn’t work, see **docs/V4_TAJWEED_SOURCES.md**.
