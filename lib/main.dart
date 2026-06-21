import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'viewmodels/editor_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/splash_screen.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => EditorViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, child) {
          return ToastificationWrapper(
            child: MaterialApp(
              title: 'Watermark Studio',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeViewModel.themeMode,
              debugShowCheckedModeBanner: false,
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
