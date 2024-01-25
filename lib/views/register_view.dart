// ignore_for_file: use_build_context_synchronously

import 'package:budget_planner_racka/auth/auth_exceptions.dart';
import 'package:budget_planner_racka/auth/bloc/auth_bloc.dart';
import 'package:budget_planner_racka/auth/bloc/auth_event.dart';
import 'package:budget_planner_racka/auth/bloc/auth_state.dart';
import 'package:budget_planner_racka/constants/colors.dart';
import 'package:budget_planner_racka/utilities/dialogs/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//// TODO pomyśleć nad powtórzeniem hasła, wyborem sposobu logowania, rozdzieleniem calosci na inne lub email itd itd

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscureText = false;
  bool _passwordMatch = true;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _obscureText = true;
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateLoggedOut) {
          if (state.exception is WrongPasswordAuthException) {
            await showErrorDialog(
              context,
              // TODO l10n
              'Podane dane są nieprawidłowe!',
            );
          }
          if (state.exception is UserNotFoundAuthException) {
            await showErrorDialog(
              context,
              // TODO l10n
              'blablabla',
            );
          } else if (state.exception is GenericAuthException) {
            await showErrorDialog(
              context,
              // TODO l10n
              'Błąd autentykacji blabla',
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 30.0, vertical: 35.0),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Image.asset(
                        'assets/main_menu_icon.png',
                        height: 100.0,
                        width: 100.0,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.register_view_join_now,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.register_view_text,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(
                      height: 50.0,
                    ),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enableSuggestions: false,
                      autocorrect: false,
                      //autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        hintText: AppLocalizations.of(context)!
                            .regiser_view_email_hintText,
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                            color: ColorConstants.dartMainThemeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                            Icons.no_encryption_gmailerrorred_rounded),
                        hintText: AppLocalizations.of(context)!
                            .register_view_password_hintText,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          icon: Icon(
                            _obscureText
                                ? Icons.remove_red_eye
                                : Icons.remove_red_eye_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                            color: _passwordMatch ? Colors.grey : Colors.red,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                            color: ColorConstants.dartMainThemeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureText,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                            Icons.no_encryption_gmailerrorred_rounded),
                        hintText: AppLocalizations.of(context)!
                            .register_view_confirm_password_hintText,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          icon: Icon(
                            _obscureText
                                ? Icons.remove_red_eye
                                : Icons.remove_red_eye_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                            color: _passwordMatch ? Colors.grey : Colors.red,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(
                            color: ColorConstants.dartMainThemeColor,
                          ),
                        ),
                      ),
                    ),
                    if (!_passwordMatch)
                      const Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          // TODO l10n
                          'Podane przez Ciebie hasła nie są takie same!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 25.0,
                    ),
                    SizedBox(
                      width: 225.0,
                      child: FilledButton(
                        onPressed: () async {
                          final email = _emailController.text;
                          final password = _passwordController.text;
                          final confirmPassword =
                              _confirmPasswordController.text;

                          if (password == confirmPassword) {
                            context.read<AuthBloc>().add(
                                  AuthEventRegister(
                                    email,
                                    password,
                                  ),
                                );
                          } else {
                            setState(
                              () {
                                _passwordMatch = password == confirmPassword;
                              },
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!
                              .register_view_register_button,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 25.0,
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                              const AuthEventShouldLogIn(),
                            );
                      },
                      child: Text.rich(
                        TextSpan(
                            text: AppLocalizations.of(context)!
                                .register_view_have_account_part1,
                            style:
                                // TODO edit color
                                const TextStyle(
                                    color: Color.fromARGB(255, 75, 75, 75)),
                            children: [
                              TextSpan(
                                  text: AppLocalizations.of(context)!
                                      .register_view_have_account_part2,
                                  style: TextStyle(
                                      color: ColorConstants.dartMainThemeColor))
                            ]),
                        textAlign: TextAlign.center,
                      ),
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
