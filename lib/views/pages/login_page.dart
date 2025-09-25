import "package:flutter/material.dart";
import "package:nearchat/server/api_service.dart";
import "package:nearchat/views/pages/home_page.dart";
import "package:nearchat/views/pages/settings_page.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  void _onRegisterPressed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _apiService.register(usernameController.text, passwordController.text);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onLoginPressed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _apiService.login(usernameController.text, passwordController.text);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
            child: Text(
          "Login",
        )),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsPage()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    hintText: "Username",
                  ),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: "Password"),
                ),
                FilledButton(
                    onPressed: _isLoading ? null : _onLoginPressed,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Login")),
                TextButton(
                    onPressed: _isLoading ? null : _onRegisterPressed,
                    child: const Text("Register")),
                if (_errorMessage != null) Text(_errorMessage!)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
