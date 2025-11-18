/// App version information
///
/// Keep this in sync with pubspec.yaml version field
class AppVersion {
  static const String version = '1.1.7';
  static const String buildNumber = '9';

  static String get fullVersion => 'v$version ($buildNumber)';
}
