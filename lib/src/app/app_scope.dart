import 'package:flutter/widgets.dart';

import 'app_state.dart';

class StockEaseScope extends InheritedNotifier<AppState> {
  const StockEaseScope({
    required AppState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StockEaseScope>();
    assert(scope != null, 'StockEaseScope not found in widget tree.');
    return scope!.notifier!;
  }
}

extension StockEaseContext on BuildContext {
  AppState get appState => StockEaseScope.of(this);
}
