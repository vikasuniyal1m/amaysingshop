class AppConfig {
  const AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'WC_BASE_URL',
    defaultValue: 'https://amaysingshop.com',
  );

  static const String consumerKey = String.fromEnvironment(
    'WC_CONSUMER_KEY',
    defaultValue: 'ck_d9287a8ca09cbe63fffddfeeaeb83f04c1f31bd0',
  );

  static const String consumerSecret = String.fromEnvironment(
    'WC_CONSUMER_SECRET',
    defaultValue: 'cs_4d3a83ee6f085b179bc50f99e26d5517b4432604',
  );

  /// Force-enable API logs in release/profile too.
  /// In debug, compact API logs are always enabled automatically.
  static const bool wooApiLogEnabled = bool.fromEnvironment(
    'WOO_API_LOG_ENABLED',
    defaultValue: false,
  );

  /// Enables verbose mode. In debug this is optional because compact logs are
  /// always on; use this to make logs more detailed when needed.
  /// `--dart-define=WOO_VERBOSE_LOG=true`
  static const bool wooApiVerboseLog = bool.fromEnvironment(
    'WOO_VERBOSE_LOG',
    defaultValue: false,
  );


  /// When true (and [wooApiVerboseLog] is true), logs full pretty-printed bodies.
  /// Very noisy — Yoast/SEO fields make responses huge. Enable only for deep API debugging:
  /// `--dart-define=WOO_VERBOSE_LOG=true --dart-define=WOO_VERBOSE_LOG_FULL=true`
  static const bool wooApiVerboseLogFull = bool.fromEnvironment(
    'WOO_VERBOSE_LOG_FULL',
    defaultValue: false,
  );
}
