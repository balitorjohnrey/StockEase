import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/stock_ease_app.dart';
import 'src/theme/app_theme.dart';
import 'src/widgets/app_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase directly with your URL and Key
  await Supabase.initialize(
    url: 'https://dscjwdkwubcqxytulqml.supabase.co',
    // Note: If you get a compilation error here, change 'publishableKey' to 'anonKey'
    publishableKey: 'sb_publishable_n7RFrDOkSD-mBr2PCDhNaA_M2U_j0W8', 
  );

  runApp(const StockEaseApp());
}

// You can safely leave this here, or delete it entirely since it's no longer being called.
class MissingConfigurationApp extends StatelessWidget {
  const MissingConfigurationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        backgroundColor: AppTheme.sky,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: AppTheme.strongShadow,
              ),
              child: const Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: BrandLogo(size: 82)),
                    SizedBox(height: 20),
                    Text(
                      'StockEase needs Supabase settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Run Flutter with SUPABASE_URL and SUPABASE_ANON_KEY '
                      'using --dart-define. The README includes the exact '
                      'command format.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}