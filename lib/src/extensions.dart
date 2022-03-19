import 'package:flutter/widgets.dart';

extension SafeStateOfWidget<T extends StatefulWidget> on State<T> {
  Future<void> safeSetState(VoidCallback fn) async {
    await Future.microtask(
      () {
        if (mounted) {
          // ignore: invalid_use_of_protected_member
          setState(fn);
        }
      },
    );
  }
}
