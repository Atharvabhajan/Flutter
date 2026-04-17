import 'dart:async';
import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/policy_screen.dart';
import 'services/auth_service.dart';
import 'services/practice_service.dart';
import 'services/stealth_mode_service.dart';
import 'services/audio_upload_queue.dart';
import 'screens/stealth_notes_screen.dart';
import 'widgets/volume_detection_listener.dart';
import 'config/api_url.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeilNote',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    await ApiUrl.loadBaseUrl();
    await AudioUploadQueue.initialize();
    final isLoggedIn = await AuthService.isLoggedIn();
    await PracticeService.initialize();
    await StealthModeService.initialize();

    // Retry any pending uploads silently
    unawaited(AudioUploadQueue.retryPendingUploads());

    if (isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool('onboardingComplete') ?? false;

      if (!isCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PolicyScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onLongPress: () => _showApiConfigDialog(context),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.note_outlined,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'VeilNote',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  void _showApiConfigDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: ApiUrl.baseUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer API Config'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Base API URL',
            hintText: 'http://192.168.x.x:5000/api',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiUrl.saveBaseUrl(controller.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('API URL updated: ${ApiUrl.baseUrl}')),
                );
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }
}

class AuthNavigation extends StatefulWidget {
  const AuthNavigation({Key? key}) : super(key: key);

  @override
  State<AuthNavigation> createState() => _AuthNavigationState();
}

class _AuthNavigationState extends State<AuthNavigation> {
  bool _showLogin = true;

  void _onAuthSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainApp()),
    );
  }

  void _toggleScreen() {
    setState(() => _showLogin = !_showLogin);
  }

  @override
  Widget build(BuildContext context) {
    return _showLogin
        ? LoginScreen(
            onLoginSuccess: _onAuthSuccess,
            onRegisterTap: _toggleScreen,
          )
        : RegisterScreen(
            onRegisterSuccess: _onAuthSuccess,
            onLoginTap: _toggleScreen,
          );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  void _onLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: StealthModeService.isStealthNotifier,
      builder: (context, isStealth, child) {
        // If stealth mode is active, show StealthNotesScreen directly (no tabs)
        if (isStealth) {
          return const StealthNotesScreen();
        }

        // Otherwise, show normal app with bottom navigation
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              VolumeDetectionListener(
                child: HomeScreen(onLogout: _onLogout),
              ),
              const GuideScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_rounded),
                label: 'Guide',
              ),
            ],
          ),
        );
      },
    );
  }
}
