# FridgeChef

**Photograph your fridge — or tick what you have — and get real recipes you can actually cook.**

FridgeChef matches what's in your fridge against a bundled book of **34 real recipes** (dal tadka, paneer butter masala, chole masala, masala dosa, chicken curry, pav bhaji and more), ranked by the percentage of ingredients you already have, with the missing ones listed so you know exactly what to buy.

## Features

- **AI photo detection** — snap a photo of your fridge and Gemini (vision) reads the ingredients for you. Needs your own Gemini API key, entered in Settings. Without a key this path honestly says a key is needed — it never fakes a detection.
- **Manual ingredient picker** — a checklist of common Indian and international ingredients, grouped by vegetables, dairy & eggs, grains & breads, spices, and proteins & pulses, plus free-text add. Works fully offline, no key needed.
- **Smart recipe matching** — every recipe is ranked by % of required ingredients you have. Pantry staples (salt, sugar) are assumed present so they don't drag scores down.
- **Filters** — veg / non-veg / all, max total time (≤15/30/45/60 min), and search by name or cuisine.
- **Full recipe detail** — ingredients with quantities and have/missing marks, numbered steps, prep + cook time, difficulty.
- **Favourites** — save recipes locally in SQLite; no account needed.
- **First-run onboarding** — explains photo vs. manual picker up front.
- **Offline-first** — the whole recipe book is bundled in the app (`assets/recipes.json`). Only the optional photo detection needs the internet.

## How the Gemini key works

1. Get a free key from Google AI Studio: https://aistudio.google.com
2. Open FridgeChef → Settings → paste your key → Save.
3. In **My Fridge**, tap **Take photo** or **From gallery**.

The key is stored only in SharedPreferences on your device. It is never committed to the repo, never sent anywhere except to Google's Gemini API (`generativelanguage.googleapis.com`) when you tap a photo button, and you can remove it any time from Settings. The app calls `gemini-2.5-flash` with the image (base64) and a prompt asking for a JSON list of visible ingredients, then parses the reply robustly (markdown fences stripped).

## The recipe dataset

`assets/recipes.json` contains 34 real, well-known recipes written from real cooking knowledge — accurate ingredients with quantities and numbered steps. No invented dishes, no placeholder content. Each recipe has: id, name, cuisine, veg/non-veg, prep + cook time, difficulty, ingredients, steps.

## Tech

- Flutter 3.50 / Dart 3.14, Material 3
- `sqflite` — favourites stored locally in SQLite
- `shared_preferences` — Gemini key, onboarding state, selected ingredients
- `image_picker` — camera / gallery photo capture
- `http` — Gemini vision REST API

## Build & run

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Requires a Gemini API key only for the photo-detection feature; everything else works without one.

## License

MIT — see [LICENSE](LICENSE).
