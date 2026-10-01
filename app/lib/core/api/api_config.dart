/// Where the API lives.
///
/// Passed at build and run time, so the same code points at localhost in
/// development and at the real domain in production, with nothing to change in
/// the source:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
///   flutter build web --dart-define=API_BASE_URL=https://api.example.com/api/v1
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
}
