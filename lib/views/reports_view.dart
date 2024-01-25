import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/firebase_cloud_transaction_storage.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/transaction_summary.dart';
import 'package:budget_planner_racka/constants/colors.dart';
import 'package:budget_planner_racka/views/report_details_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({Key? key}) : super(key: key);

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  late Stream<Iterable<CloudTransactionDetails>> _transactionStream;
  late TransactionSummary _transactionSummary;
  final List<ReportData> _reportDataList = [];

  @override
  void initState() {
    _transactionSummary = TransactionSummary();
    _loadTransactions();
    super.initState();
  }

  void _loadTransactions() {
    String ownerUserId = FirebaseAuth.instance.currentUser!.uid.toString();

    _transactionStream =
        FirebaseCloudTransactionStorage().getAllTransactionDetails(
      ownerUserId: ownerUserId,
    );

    _transactionStream.listen((transactions) {
      _reportDataList.clear();

      for (var transaction in transactions) {
        _transactionSummary.processTransaction(transaction);
      }

      Map<String, List<CloudTransactionDetails>> transactionsByMonth = {};

      for (var transaction in transactions) {
        String key = DateFormat('yyyy-MM').format(transaction.date);
        transactionsByMonth.putIfAbsent(key, () => []).add(transaction);
      }

      transactionsByMonth.forEach((key, monthTransactions) {
        _transactionSummary.resetSummary();

        for (var transaction in monthTransactions) {
          _transactionSummary.processTransaction(transaction);
        }

        double totalAmount =
            _transactionSummary.income - _transactionSummary.expenses;

        var dateParts = key.split('-');
        int year = int.parse(dateParts[0]);
        int month = int.parse(dateParts[1]);

        _reportDataList.add(
          ReportData(
            month: DateFormat('MMMM', 'pl_PL').format(DateTime(year, month)),
            year: year,
            totalAmount: totalAmount,
          ),
        );
      });

      setState(() {
        _transactionSummary.resetSummary();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO l10n
        title: const Text('Raporty'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _reportDataList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailsView(
                    month: _reportDataList[index].month,
                    year: _reportDataList[index].year,
                    totalAmount: _reportDataList[index].totalAmount,
                  ),
                ),
              );
            },
            child: Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              height: 100.0,
              decoration: BoxDecoration(
                color: ColorConstants.lightMainThemeColor,
                border: Border.all(
                  color: ColorConstants.dartMainThemeColor,
                ),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${capitalize(_reportDataList[index].month)} ${_reportDataList[index].year}',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      // TODO l10n
                      'Kwota w miesiącu: ${_reportDataList[index].totalAmount.toStringAsFixed(2)} zł',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class ReportData {
  final String month;
  final int year;
  final double totalAmount;

  ReportData({
    required this.month,
    required this.year,
    required this.totalAmount,
  });
}
