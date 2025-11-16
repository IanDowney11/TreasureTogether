# Photo Sharing App

A mobile app for seamless photo sharing during trips and outings with offline-first capabilities.

## Features

- Create and join photo sharing groups
- Upload photos with offline queue
- View shared photos in gallery
- Download photos for offline viewing
- Supabase backend with local data storage
- Cross-platform (iOS & Android)

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Supabase (Database + Storage + Auth)
- **Local Storage**: SQLite + local file cache

## Getting Started

1. Install Flutter SDK
2. Run `flutter pub get`
3. Set up Supabase project (instructions below)
4. Add your Supabase credentials to `lib/config/supabase_config.dart`
5. Run `flutter run`

## Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Note your project URL and anon key
3. Run the SQL schema from `supabase/schema.sql`
4. Configure storage bucket for photos

## Project Structure

```
lib/
├── main.dart
├── config/
│   └── supabase_config.dart
├── models/
│   ├── group.dart
│   ├── photo.dart
│   └── user.dart
├── services/
│   ├── auth_service.dart
│   ├── photo_service.dart
│   ├── group_service.dart
│   └── sync_service.dart
├── screens/
│   ├── auth/
│   ├── groups/
│   ├── gallery/
│   └── camera/
├── widgets/
└── utils/
```