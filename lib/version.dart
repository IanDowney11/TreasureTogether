/// App version information
///
/// Keep this in sync with pubspec.yaml version field
class AppVersion {
  static const String version = '2.1.0';
  static const String buildNumber = '13';

  static String get fullVersion => 'v$version ($buildNumber)';
}
