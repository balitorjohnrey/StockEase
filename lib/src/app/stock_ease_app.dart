import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth_screens.dart';
import '../screens/business_setup_screen.dart';
import '../screens/home_shell.dart';
import '../screens/splash_screen.dart';
import '../theme/app_theme.dart';
import 'app_scope.dart';
import 'app_state.dart';

class StockEaseApp extends StatefulWidget {
  const StockEaseApp({super.key});

  @override
  State<StockEaseApp> createState() => _StockEaseAppState();
}

class _StockEaseAppState extends State<StockEaseApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState(Supabase.instance.client);
    _state.bootstrap();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StockEaseScope(
      state: _state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'StockEase',
        theme: AppTheme.light(),
        home: AnimatedBuilder(
          animation: _state,
          builder: (context, _) {
            if (_state.isBootstrapping) return const SplashScreen();
            if (!_state.isAuthenticated) return const AuthScreen();
            if (_state.business == null) return const BusinessSetupScreen();
            return const HomeShell();
          },
        ),
      ),
    );
  }
}
