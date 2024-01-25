import 'package:budget_planner_racka/views/history_view.dart';
import 'package:budget_planner_racka/views/reports_view.dart';
import 'package:budget_planner_racka/views/start_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomNavbarView extends StatefulWidget {
  const BottomNavbarView({super.key});

  @override
  State<BottomNavbarView> createState() => _BottomNavbarViewState();
}

class _BottomNavbarViewState extends State<BottomNavbarView> {
  int _currentIndex = 0;
  List<Widget> widgetList = const [
    StartView(),
    HistoryView(),
    ReportsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widgetList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.bottom_navbar_home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt),
            label: AppLocalizations.of(context)!.bottom_navbar_history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            label: AppLocalizations.of(context)!.bottom_navbar_reports,
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
