# Movizius

A mobile app for browsing movies and TV series, watching trailers, and managing a personal watchlist — built with Flutter.

## Features

- Auth0 login/logout with secure token storage and route protection
- Browse and search movies and TV series (powered by TMDB)
- Movie and TV series detail pages (cast, providers, seasons/episodes, etc.)
- Personal watchlist synced with a remote API
- Trailer playback via embedded YouTube player
- Push notifications (Firebase Cloud Messaging)

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Networking:** Dio (with logging/auth interceptors)
- **Authentication:** Auth0
- **Push Notifications:** Firebase Cloud Messaging
- **Local Storage:** Flutter Secure Storage (tokens), SharedPreferences (simple preferences)
- **Data Sources:** TMDB API, a custom Watchlist API

## Architecture

Feature-first architecture:

```
lib/
  core/          # network, router, auth, theme, shared widgets, utils
  features/
    auth/
    movies/
    series/
    watchlist/
    search/
    explore/
    home/
    person/
    profile/
    watch_providers/
```

Each feature is organized into `models/`, `repositories/` (or `services/`), `providers/`, `pages/`, and `widgets/` as needed. Business logic lives in providers/repositories; pages and widgets stay focused on presentation.

## Getting Started

1. Install the Flutter SDK (see `environment.sdk` in `pubspec.yaml` for the required version).
2. Copy `.env.example` to `.env` and fill in your own credentials (Auth0, TMDB, Watchlist API). Never commit your real `.env`.
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run the app:
   ```
   flutter run
   ```

## Notes

- The watchlist is server-side only; no local persistence of watchlist data.
- Tokens are stored exclusively in Flutter Secure Storage, never in SharedPreferences.
