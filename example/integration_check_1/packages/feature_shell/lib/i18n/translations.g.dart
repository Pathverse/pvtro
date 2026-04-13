import 'package:flutter/widgets.dart';

/// Mimics the slang locale settings API for the feature shell fixture package.
class LocaleSettings {
  /// Accepts a raw locale code for the feature shell fixture package.
  static Future<void> setLocaleRaw(String rawLocale) async {}
}

/// Exposes the feature shell translation layer for the integration fixture.
class TranslationProvider extends StatelessWidget {
  final Widget child;

  /// Creates the feature shell translation provider fixture.
  const TranslationProvider({super.key, required this.child});

  @override
  /// Returns the wrapped child for the feature shell translation fixture.
  Widget build(BuildContext context) {
    return child;
  }
}
