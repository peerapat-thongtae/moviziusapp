# CLAUDE.md

## Project Overview

Movie & TV Series Watchlist mobile application built with Flutter.

Primary features:

* User authentication via Auth0
* Browse movies and TV series from TMDB
* View movie and TV details
* Manage personal watchlists
* Watch trailers via YouTube
* Search movies and TV series
* Sync watchlists with remote API

---

## Environment Variables

Environment variables are stored in:

.env

## Tech Stack

### Framework

* Flutter (latest stable)

### State Management

* Riverpod

### Routing

* GoRouter

### Networking

* Dio

### Authentication

* Auth0

### APIs

* TMDB API
* Watchlist API

### Local Storage

Only use:

* Flutter Secure Storage (tokens)
* SharedPreferences (simple preferences)

Do NOT introduce Hive, Drift, Isar, or SQLite unless explicitly required.

---

## Architecture

Use Feature-First Architecture.

Example:

lib/

core/
network/
router/
auth/
constants/
theme/

features/
auth/
movies/
series/
watchlist/
search/
profile/

Each feature may contain:

features/<feature>/

models/
repositories/
providers/
pages/
widgets/

Avoid creating unnecessary layers.

---

## Architecture Rules

### Allowed

* Repository pattern
* Service classes
* Riverpod providers
* DTO models

### Avoid

* Clean Architecture
* UseCase classes
* Entity classes
* Mapper classes unless truly necessary
* Over-abstraction

The project should prioritize simplicity and delivery speed.

---

## State Management Rules

Use Riverpod for all application state.

Preferred:

* AsyncNotifier
* Notifier
* FutureProvider

Avoid:

* Global singletons
* Manual service locators

---

## Networking Rules

All API calls must go through Dio.

Create shared configuration inside:

core/network/

Requirements:

* Timeout configuration
* Logging interceptor
* Auth interceptor
* Error handling

Do not call TMDB directly from widgets.

---

## UI Rules

Follow Material 3.

Pages should remain lightweight.

Business logic belongs in:

every section called api should has skeleton loading.

every page should have pull to refresh.

* providers
* repositories

Widgets should focus on presentation.

Every feature should include animation or transition (e.g. page transitions, implicit animations, `AnimatedSwitcher`, Hero animations) rather than static/instant UI changes. Keep animations simple and idiomatic to Flutter/Material 3 — avoid heavy custom animation frameworks unless explicitly required.

Should design UI as reuseable shared components.

This app should responsive on mobile and tablet.

In every features should smoothly priority first.

When create UI with mock data should mock from real services function. and integrate at those function later.

The designs of movies and series should be similar; when you modify one, you should modify the other as well. (ex. detail page, card, other)

---

## Authentication Rules

Auth0 is the single authentication provider.

Requirements:

* Login
* Logout
* Token refresh
* Route protection

Never store tokens in SharedPreferences.

Use Flutter Secure Storage.

---

## Watchlist Rules

Watchlist is server-side.

Do not store watchlists locally.

Source of truth:

* Watchlist API

---

## Trailer Rules

Trailers are provided through YouTube.

Use embedded playback.

Avoid downloading videos.

---

## Code Style

Requirements:

* Prefer immutable models
* Prefer const constructors
* Use meaningful names
* Keep files small
* Keep widgets focused

Avoid:

* Large God classes
* Business logic in UI
* Deep inheritance hierarchies

Favor composition over inheritance.

---

## Dependencies Policy

Before adding a new dependency:

1. Verify Flutter SDK does not already solve the problem.
2. Verify existing dependency cannot solve the problem.
3. Prefer actively maintained packages.
4. Keep dependency count low.

---

## Testing

No need test for this project.

---

## Goal

Build a maintainable Flutter application with minimal complexity.

Prefer simple solutions over architectural purity.
