import 'package:flutter/widgets.dart';

/// Mimics the slang locale settings API for the shared checkout fixture package.
class LocaleSettings {
  /// Accepts a raw locale code for the shared checkout fixture package.
  static Future<void> setLocaleRaw(String rawLocale) async {}
}

/// Exposes the shared checkout translation layer for the integration fixture.
class TranslationProvider extends StatelessWidget {
  final Widget child;

  /// Creates the shared checkout translation provider fixture.
  const TranslationProvider({super.key, required this.child});

  @override
  /// Returns the wrapped child for the shared checkout translation fixture.
  Widget build(BuildContext context) {
    return child;
  }
}
