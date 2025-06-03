import 'package:botctracker/src/personal_statistics_view.dart';
import 'package:botctracker/src/statistics_selection_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'home_view.dart';
import 'add_game_view.dart';
import 'statistics_view.dart';
import 'profile_view.dart';
import 'sign_in_view.dart';
import 'saved_games_view.dart';
import 'game_details_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.red,
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Cinzel',
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Cinzel', color: Colors.black),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            fontFamily: 'Cinzel',
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Cinzel', color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          themeMode: settingsController.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case AddGameView.routeName:
                    return const AddGameView();
                  case StatisticsView.routeName:
                    return const StatisticsView();
                  case ProfileView.routeName:
                    return const ProfileView();
                  case SavedGamesView.routeName:
                    return const SavedGamesView();
                  case StatisticsSelectionView.routeName:
                    return const StatisticsSelectionView();
                  case PersonalStatisticsView.routeName:
                    return const PersonalStatisticsView();
                  case GameDetailsView.routeName:
                    final args = routeSettings.arguments as Map<String, String>;
                    return GameDetailsView(
                      gameId: args['gameId']!,
                      userId: args['userId']!,
                    );
                  case HomeView.routeName:
                  default:
                    return const AuthGate();
                }
              },
            );
          },
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return const HomeView();
        } else {
          return const SignInView();
        }
      },
    );
  }
}
