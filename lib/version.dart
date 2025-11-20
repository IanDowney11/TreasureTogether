/// App version information
///
/// Keep this in sync with pubspec.yaml version field
class AppVersion {
  static const String version = '2.0.1';
  static const String buildNumber = '12';

  static String get fullVersion => 'v$version ($buildNumber)';
}
