---
name: add-hadith-collection
description: Add a new hadith collection or an individual book to Hublee. Use when adding hadith JSON assets, registering a collection directory, wiring a new book into the hadith tab, or when a newly added hadith book is not appearing in the app or in search.
---

# Add a hadith collection or book

Adding hadith data touches four places. Missing any one of them fails quietly — the app
catches the error and just omits the collection, so nothing appears and no error shows.

## Step 1 — Decide: new book, or new collection?

- **New book in an existing collection** (`forties`, `the_9_books`, `other_books`):
  do steps 2 and 3 only.
- **New collection** (a new directory): do all steps. Step 5 is the one that is easy to
  forget and is the usual reason a collection never shows up.

## Step 2 — Add the book JSON

Place the file at `assets/hadith/<collectionId>/<book>.json`. The shape parsed by
`HadithRepository.loadBook` is:

```json
{
  "metadata": { "english": { "title": "..." }, "arabic": { "title": "..." } },
  "chapters": [
    { "id": 1, "bookId": 1, "arabic": "...", "english": "..." }
  ],
  "hadiths": [
    {
      "id": 1,
      "idInBook": 1,
      "chapterId": 1,
      "bookId": 1,
      "arabic": "...",
      "english": { "narrator": "...", "text": "..." }
    }
  ]
}
```

`chapters` and `hadiths` are both optional in the parser (a missing key yields an empty
list), so a typo in either key produces an empty book rather than an error. Verify the
counts after loading.

Requirements for the text itself:

- Preserve all diacritics in the Arabic. Never strip tashkeel.
- Keep honorifics (ﷺ, رضي الله عنه) exactly as sourced.
- Do not invent grading (`sahih` / `hasan` / `da'if`). If the source has no grading,
  leave it out — see `hadith-guidelines.mdc`.

## Step 3 — Register the book in the collection index

Add an entry to `assets/hadith/<collectionId>/index.json`. `loadBooksForCollection`
accepts three shapes; match whatever the existing index in that directory already uses:

```json
[{ "file": "nawawi40.json", "bookName": "Nawawi 40", "length": 42 }]
```

```json
{ "books": [ ... ] }
```

```json
{ "nawawi40.json": "Nawawi 40" }
```

A book that exists on disk but is absent from `index.json` will never be listed.

## Step 4 — Declare the asset directory in `pubspec.yaml`

Each collection directory is listed individually under `flutter: assets:`:

```yaml
    - assets/hadith/forties/
    - assets/hadith/other_books/
    - assets/hadith/the_9_books/
    - assets/hadith/<collectionId>/   # add this for a new collection
```

A trailing slash bundles the whole directory, so a new book in an already-declared
directory needs no pubspec change. A **new** directory does.

## Step 5 — Register a new collection in the repository

The collection list is **hard-coded**, not read from `collections.json`. Add an entry to
`knownCollections` inside `loadCollections()` in `lib/hadith/hadith_repository.dart`:

```dart
const knownCollections = <HadithCollectionMeta>[
  HadithCollectionMeta(id: 'forties', title: 'Forties'),
  HadithCollectionMeta(id: 'the_9_books', title: 'The Nine Books'),
  HadithCollectionMeta(id: 'other_books', title: 'Other Books'),
  HadithCollectionMeta(id: '<collectionId>', title: '<Display Title>'),
];
```

`id` must exactly match the directory name. `title` becomes the section header on the
hadith tab. This one entry is what makes the collection appear in the tab **and** in
`HadithSearchService`, since search iterates the same list.

## Step 6 — Verify

Do not stop at "it compiles". Confirm all four:

1. `flutter analyze` and `dart format --output=none --set-exit-if-changed lib test tools`
   are clean.
2. Run the app and open the Hadith tab — the collection appears with a correct book count.
3. Open a book — chapters and hadiths render, Arabic shows full diacritics, and the
   narrator appears in its own container.
4. Search for a distinctive phrase from the new book — it appears with the right book
   name and number.

If the collection is missing from the tab, the cause is almost always step 5, or an `id`
that doesn't match the directory name. `loadCollections` swallows the exception from a
missing `index.json`, and `searchAll` skips collections that fail to load.
