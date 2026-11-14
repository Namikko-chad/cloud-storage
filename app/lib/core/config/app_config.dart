/// Build-time identifiers (--dart-define). Never hard-coded (§ 6.3).
abstract final class AppConfig {
  static const version = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');
  static const buildSha = String.fromEnvironment('BUILD_SHA', defaultValue: 'dev');
  /// Unique per make run; the core built in the same run reports the same.
  static const buildId = String.fromEnvironment('BUILD_ID', defaultValue: 'dev');
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get shortSha => buildSha.length > 7 ? buildSha.substring(0, 7) : buildSha;
}
