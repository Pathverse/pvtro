import 'package:flutter/widgets.dart';
import 'package:integration_check_2/generated/pvtro_wrapper.g.dart';

/// Bootstraps the real slang integration example.
void main() {
  runApp(pvtroWrapper(child: const ExampleApp()));
}

/// Hosts a minimal widget tree for the real slang integration fixture.
class ExampleApp extends StatelessWidget {
  /// Creates the root widget for the integration fixture.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.expand(),
    );
  }
}
