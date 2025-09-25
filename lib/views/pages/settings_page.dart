import "package:flutter/material.dart";
import "package:nearchat/data/notifiers.dart";
import "package:nearchat/server/api_service.dart";
import "package:nearchat/views/pages/login_page.dart";

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiService = ApiService();

  bool _isLoading = false;

  void _onLogoutPressed() {
    setState(() {
      _isLoading = true;
    });

    try {
      _apiService.logout();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false);
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Settings")),
        actions: [
          ValueListenableBuilder(
            valueListenable: darkModeEnabledNotifier,
            builder: (context, isDark, child) {
              return IconButton(
                  onPressed: () {
                    darkModeEnabledNotifier.value =
                        !darkModeEnabledNotifier.value;
                  },
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode));
            },
          ), IconButton(onPressed: _isLoading ? null : _onLogoutPressed, icon: _isLoading ? CircularProgressIndicator() : Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FilledButton(
                onPressed: _isLoading ? null : _onLogoutPressed,
                child: _isLoading ? CircularProgressIndicator() : Text("Logout"))
          ],
        ),
      ),
    );
  }
}
