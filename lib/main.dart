import "package:flutter/material.dart";
import "package:nearchat/server/token_storage.dart";
import "package:nearchat/views/pages/home_page.dart";
import "package:nearchat/views/pages/login_page.dart";
import "package:nearchat/data/notifiers.dart";

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: darkModeEnabledNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
            title: "Nearchat",
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                    brightness:
                        isDarkMode ? Brightness.dark : Brightness.light)),
            home: FutureBuilder(
                future: TokenStorage().hasToken(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading");
                  } else {
                    final hasToken = snapshot.data ?? false;
                    return hasToken ? const HomePage() : const LoginPage();
                  }
                }));
      },
    );
  }
}
