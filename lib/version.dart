/// App version information
///
/// Keep this in sync with pubspec.yaml version field
class AppVersion {
  static const String version = '1.1.8';
  static const String buildNumber = '10';

  static String get fullVersion => 'v$version ($buildNumber)';
}
