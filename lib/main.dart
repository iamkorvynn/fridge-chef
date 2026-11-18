import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/settings_service.dart';
import 'state/app_state.dart';

void main() {
  runApp(const FridgeChefApp());
}

class FridgeChefApp extends StatefulWidget {
  const FridgeChefApp({super.key});

  @override
  State<FridgeChefApp> createState() => _FridgeChefAppState();
}

class _FridgeChefAppState extends State<FridgeChefApp> {
  final AppState _state = AppState();
  bool _onboardingDone = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _state.init();
    final done = await SettingsService().onboardingDone;
    if (mounted) {
      setState(() {
        _onboardingDone = done;
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FridgeChef',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: !_ready
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _onboardingDone
              ? HomeScreen(state: _state)
              : OnboardingScreen(
                  onDone: () => setState(() => _onboardingDone = true),
                ),
    );
  }
}
