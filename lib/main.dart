import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:remote_mouse/providers/cache_provider.dart';
import 'package:remote_mouse/providers/settings_provider.dart';
import 'package:remote_mouse/providers/theme_provider.dart';
import 'package:remote_mouse/providers/web_socket_provider.dart';
import 'package:remote_mouse/screens/home_screen.dart';
import 'package:remote_mouse/screens/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CacheProvider()),
        ChangeNotifierProxyProvider<CacheProvider, ThemeProvider>(
          create: (context) {
            final cache = context.read<CacheProvider>();
            return ThemeProvider(cache)..loadThemeData();
          },
          update: (context, cache, theme) => theme!..loadThemeData(),
        ),
        ChangeNotifierProxyProvider<CacheProvider, SettingsProvider>(
          create: (context) {
            final cache = context.read<CacheProvider>();
            return SettingsProvider(cache)..loadPreferences();
          },
          update: (_, cache, settings) {
            return settings!..loadPreferences();
          },
        ),
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Remote Mouse',
      themeMode: themeProvider.themeMode,
      theme: ThemeProvider.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          ThemeProvider.lightTheme.textTheme,
        ),
      ),
      darkTheme: ThemeProvider.darkTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          ThemeProvider.darkTheme.textTheme,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
