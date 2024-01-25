import 'dart:developer';

import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_type.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/firebase_cloud_transaction_storage.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/transaction_summary.dart';
import 'package:budget_planner_racka/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportDetailsView extends StatefulWidget {
  final String month;
  final int year;
  final double totalAmount;

  const ReportDetailsView({
    Key? key,
    required this.month,
    required this.year,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<ReportDetailsView> createState() => _ReportDetailsViewState();
}

class _ReportDetailsViewState extends State<ReportDetailsView> {
  List<ChartTransactionData> chartData = [];
  List<ChartTransactionData> dailyChartData = [];

  @override
  Widget build(BuildContext context) {
    String ownerUserId = FirebaseAuth.instance.currentUser!.uid;
    DateTime selectedMonth =
        DateTime(widget.year, _getMonthNumber(widget.month));
    TransactionSummary summary = TransactionSummary();

    return Scaffold(
      appBar: AppBar(
        title: Text('Raport ${capitalize(widget.month)} ${widget.year}'),
        centerTitle: true,
      ),
      body: StreamBuilder<Iterable<CloudTransactionDetails>>(
        stream: FirebaseCloudTransactionStorage().getTransactionsForMonth(
          ownerUserId: ownerUserId,
          month: selectedMonth,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Brak danych'),
            );
          } else {
            List<CloudTransactionDetails> transactions =
                snapshot.data?.toList() ?? [];

            summary.resetSummary();
            for (var transaction in transactions) {
              summary.processTransaction(transaction);
              log('DATAAAAAA ${transaction.date}');
            }

            transactions = transactions.toList();
            updateChartData(transactions);

            return SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Column(
                  children: [
                    const Text(
                      // TODO l10n
                      'Wydatki i przychody',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(
                      height: 300.0,
                      child: SfCartesianChart(
                        primaryXAxis: const CategoryAxis(),
                        series: [
                          ColumnSeries<ChartTransactionData, String>(
                            dataSource: chartData,
                            xValueMapper: (ChartTransactionData data, _) =>
                                data.category,
                            yValueMapper: (ChartTransactionData data, _) =>
                                data.amount,
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                            pointColorMapper: (ChartTransactionData data, _) {
                              if (data.category == 'Zakupy') {
                                return ColorConstants.logoLeafColor;
                              } else if (data.category == 'Restaur.') {
                                return ColorConstants.yellowFromCoinColor;
                              } else if (data.category == 'Odzież') {
                                return ColorConstants.lightMainThemeColor;
                              }
                              return ColorConstants.dartMainThemeColor;
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    // TODO l10n
                    const Text(
                      'Suma wydatków z każdego dnia',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(
                      height: 300.0,
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(
                          dateFormat: DateFormat('dd'),
                          title: const AxisTitle(text: 'Dzień'),
                          interval: 2,
                          labelRotation: 45,
                        ),
                        series: [
                          ColumnSeries<ChartTransactionData, DateTime>(
                            dataSource: dailyChartData,
                            xValueMapper: (ChartTransactionData data, _) =>
                                data.date,
                            yValueMapper: (ChartTransactionData data, _) =>
                                data.amount,
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                            pointColorMapper: (ChartTransactionData data, _) {
                              return ColorConstants.dartMainThemeColor;
                            },
                          )
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 15.0,
                    ),
                    // TODO l10n
                    const Text(
                      'Podsumowanie',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    // TODO l10n
                    RichText(
                      text: TextSpan(
                        text:
                            'Wydatki w ${capitalize(widget.month)} ${widget.year}: ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: '${summary.expenses.toStringAsFixed(2)} zł',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    // TODO l10n
                    RichText(
                      text: TextSpan(
                        text:
                            'Przychody w ${capitalize(widget.month)} ${widget.year}: ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: '${summary.income.toStringAsFixed(2)} zł',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5.0,
                    ),
                    // TODO l10n
                    RichText(
                      text: TextSpan(
                        text:
                            'Saldo w ${capitalize(widget.month)} ${widget.year}: ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                '${(summary.income - summary.expenses).toStringAsFixed(2)} zł',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 50.0,
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  TransactionType typeFromString(String typeString) {
    switch (typeString) {
      case 'TransactionType.groceries':
        return TransactionType.groceries;
      case 'TransactionType.restaurant':
        return TransactionType.restaurant;
      case 'TransactionType.clothes':
        return TransactionType.clothes;
      case 'TransactionType.salary':
        return TransactionType.salary;
      default:
        // TODO l10n
        throw ArgumentError('Nieznany typ transakcji: $typeString');
    }
  }

  // TODO l10n
  String typeToString(TransactionType type) {
    switch (type) {
      case TransactionType.groceries:
        return 'Zakupy';
      case TransactionType.restaurant:
        return 'Restaur.';
      case TransactionType.clothes:
        return 'Odzież';
      case TransactionType.salary:
        return 'Przychody';
      default:
        throw ArgumentError('Nieznany typ transakcji: $type');
    }
  }

  void updateChartData(List<CloudTransactionDetails> transactions) {
    chartData = [];
    List<TransactionType> transactionTypes = TransactionType.values.toList();
    Map<TransactionType, double> categoryMap = {};
    Map<DateTime, Map<TransactionType, double>> dailyMap = {};

    // Inicjalizacja mapy kategorii
    for (var type in transactionTypes) {
      categoryMap[type] = 0.0;
    }

    for (var transaction in transactions) {
      categoryMap.update(
        typeFromString(transaction.type),
        (value) => value + transaction.amount,
      );

      if (transaction.type != 'TransactionType.salary') {
        dailyMap
            .putIfAbsent(transaction.date,
                () => {typeFromString(transaction.type): transaction.amount})
            .update(
              typeFromString(transaction.type),
              (value) => value + transaction.amount,
            );
      }
    }

    // Aktualizacja danych kategorii
    categoryMap.forEach((type, amount) {
      chartData.add(
        ChartTransactionData(typeToString(type), amount, date: DateTime.now()),
      );
    });

    // Aktualizacja danych dziennych
    dailyMap.forEach((date, typeAmountMap) {
      typeAmountMap.forEach((type, amount) {
        dailyChartData.add(
          ChartTransactionData(typeToString(type), amount, date: date),
        );
      });
    });
  }

  int _getMonthNumber(String month) {
    switch (month.toLowerCase()) {
      case 'styczeń':
        return 1;
      case 'luty':
        return 2;
      case 'marzec':
        return 3;
      case 'kwiecień':
        return 4;
      case 'maj':
        return 5;
      case 'czerwiec':
        return 6;
      case 'lipiec':
        return 7;
      case 'sierpień':
        return 8;
      case 'wrzesień':
        return 9;
      case 'październik':
        return 10;
      case 'listopad':
        return 11;
      case 'grudzień':
        return 12;
      default:
        throw FormatException('Invalid month format: $month');
    }
  }
}

class ChartTransactionData {
  final String category;
  final double amount;
  final DateTime date;

  ChartTransactionData(
    this.category,
    this.amount, {
    required this.date,
  });
}
