import 'package:flutter/widgets.dart';

/// Mimics the slang locale settings API for the root fixture package.
class LocaleSettings {
  /// Accepts a raw locale code for the root fixture package.
  static Future<void> setLocaleRaw(String rawLocale) async {}
}

/// Exposes the root translation layer for the integration fixture.
class TranslationProvider extends StatelessWidget {
  final Widget child;

  /// Creates the root translation provider fixture.
  const TranslationProvider({super.key, required this.child});

  @override
  /// Returns the wrapped child for the root translation fixture.
  Widget build(BuildContext context) {
    return child;
  }
}
