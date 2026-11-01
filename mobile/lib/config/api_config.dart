// Android emülatöründen geliştirici bilgisayarına erişim adresi.
// Başka ortamlar için: --dart-define=API_BASE_URL=https://sunucunuz.example
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5199',
);
