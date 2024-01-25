import 'dart:developer';

import 'package:budget_planner_racka/auth/bloc/auth_bloc.dart';
import 'package:budget_planner_racka/auth/bloc/auth_event.dart';
import 'package:budget_planner_racka/auth/bloc/auth_state.dart';
import 'package:budget_planner_racka/auth/firebase_auth_provider.dart';
import 'package:budget_planner_racka/constants/routes.dart';
import 'package:budget_planner_racka/helpers/loading_screen.dart';
import 'package:budget_planner_racka/views/forgot_password_view.dart';
import 'package:budget_planner_racka/views/history_view.dart';
import 'package:budget_planner_racka/views/login_view.dart';
import 'package:budget_planner_racka/views/bottom_navbar_view.dart';
import 'package:budget_planner_racka/views/user_details_view.dart';
import 'package:budget_planner_racka/views/register_view.dart';
import 'package:budget_planner_racka/views/verify_email_view.dart';
import 'package:budget_planner_racka/views/welcome_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'Growly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 132, 189, 98),
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => AuthBloc(
          FirebaseAuthProvider(),
        ),
        child: const HomePage(),
      ),
      routes: {
        mainRoute: (context) => const BottomNavbarView(),
        historyRoute: (context) => const HistoryView(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventInitialize());
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isLoading) {
          LoadingScreen().show(
            context: context,
            text: state.loadingText ??
                AppLocalizations.of(context)!.auth_state_loading_text,
          );
        } else {
          LoadingScreen().hide();
        }
      },
      builder: (context, state) {
        if (state is AuthStateLoggedIn) {
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: _getUserDetails(state.user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final userDetailsDoc = snapshot.data;

                if (userDetailsDoc != null) {
                  final firstTime = userDetailsDoc['firstTime'] ?? true;
                  log('firstTime: $firstTime');

                  if (!firstTime) {
                    return const BottomNavbarView();
                  }
                }

                return const UserDetailsView();
              }
            },
          );
        } else if (state is AuthStateLoggingIn) {
          return const LoginView();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return const WelcomeView();
        } else if (state is AuthStateForgotPassword) {
          return const ForgotPasswordView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserDetails(
      String userId) async {
    final userDetailsCollection =
        FirebaseFirestore.instance.collection('userDetails');
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await userDetailsCollection.where('user_id', isEqualTo: userId).get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first;
    } else {
      return null;
    }
  }
}
