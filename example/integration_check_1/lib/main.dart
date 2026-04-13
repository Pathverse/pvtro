import 'package:flutter/widgets.dart';
import 'package:integration_check_1/pvtro.g.dart';

/// Bootstraps the integration example with the generated pvtro wrapper.
void main() {
  runApp(pvtroWrapper(child: const ExampleApp()));
}

/// Hosts a minimal widget tree for the integration fixture.
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
