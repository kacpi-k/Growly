import 'dart:developer';

import 'package:budget_planner_racka/auth/bloc/auth_bloc.dart';
import 'package:budget_planner_racka/auth/bloc/auth_event.dart';
import 'package:budget_planner_racka/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> showPasswordResetSentDialog(BuildContext context) {
  log('przed wysłaniem maila');
  return showGenericDialog(
      context: context,
      title: AppLocalizations.of(context)!.dialog_password_reset,
      content: AppLocalizations.of(context)!.dialog_link_sent,
      optionsBuilder: () => {
            'OK': () {
              context.read<AuthBloc>().add(const AuthEventLogOut());
            }
          });
}
