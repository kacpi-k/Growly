import 'dart:developer';

import 'package:budget_planner_racka/auth/bloc/auth_bloc.dart';
import 'package:budget_planner_racka/auth/bloc/auth_event.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_type.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/firebase_cloud_transaction_storage.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/transaction_summary.dart';
import 'package:budget_planner_racka/cloud/cloud_user/cloud_user_details.dart';
import 'package:budget_planner_racka/constants/colors.dart';
import 'package:budget_planner_racka/enums/menu_action.dart';
import 'package:budget_planner_racka/utilities/dialogs/logout_dialog.dart';
import 'package:budget_planner_racka/views/new_transaction_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StartView extends StatefulWidget {
  const StartView({super.key});

  @override
  State<StartView> createState() => _StartViewState();
}

class _StartViewState extends State<StartView> {
  CloudUserDetails? _userDetails;

  Stream<Iterable<CloudTransactionDetails>>? transactionStream;

  List<ChartTransactionsData> chartData = [];

  @override
  void initState() {
    _loadUserDetails();
    transactionStream =
        FirebaseCloudTransactionStorage().getTransactionsForMonth(
      ownerUserId: FirebaseAuth.instance.currentUser!.uid.toString(),
      month: DateTime.now(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log('BUILD');
    TransactionSummary summary = TransactionSummary();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 35.0),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          height: MediaQuery.of(context).size.height - 90.0,
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  if (_userDetails == null)
                    const CircularProgressIndicator()
                  else
                    Container(
                      height: 45.0,
                      width: 45.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100.0),
                        image: DecorationImage(
                          image: _userDetails?.url == ''
                              ? const AssetImage('assets/default_user_icon.png')
                                  as ImageProvider<Object>
                              : NetworkImage(_userDetails!.url),
                        ),
                      ),
                    ),
                  const SizedBox(
                    width: 10.0,
                  ),
                  if (_userDetails?.name == null)
                    //TODO l10n
                    const Text('Witaj,\nUżytkowniku')
                  else
                    //TODO l10n
                    Text('Witaj,\n${_userDetails?.name}'),
                  const Spacer(),
                  PopupMenuButton<MenuAction>(
                    onSelected: (value) {
                      if (value == MenuAction.logout) {
                        showLogOutDialog(context).then((shouldLogout) {
                          if (shouldLogout) {
                            context
                                .read<AuthBloc>()
                                .add(const AuthEventLogOut());
                          }
                        });
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem<MenuAction>(
                          value: MenuAction.logout,
                          child: Text('Logout'),
                        ),
                      ];
                    },
                  )
                ],
              ),
              const SizedBox(
                height: 25.0,
              ),
              StreamBuilder<Iterable<CloudTransactionDetails>>(
                stream: transactionStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    //TODO custom error handling
                    return Text('Błąd: ${snapshot.error}');
                  } else {
                    log(snapshot.data.toString());

                    List<CloudTransactionDetails> transactions = [];
                    if (snapshot.data != null) {
                      transactions = snapshot.data?.toList() ?? [];
                    }

                    summary.resetSummary();
                    for (var transaction in transactions) {
                      summary.processTransaction(transaction);
                    }

                    transactions = transactions.toList();

                    updateChartData(transactions);

                    transactions = transactions.take(3).toList();

                    log('Summary on StartView: Salary: ${summary.income}, Expenses: ${summary.expenses}');

                    Widget chartsContainer = SizedBox(
                      height: 125.0,
                      width: MediaQuery.of(context).size.width / 2.5,
                      child: SfCircularChart(
                        series: <CircularSeries>[
                          DoughnutSeries<ChartTransactionsData, String>(
                            dataSource: chartData,
                            xValueMapper: (ChartTransactionsData data, _) =>
                                data.category,
                            yValueMapper: (ChartTransactionsData data, _) =>
                                data.amount,
                            pointColorMapper: (ChartTransactionsData data, _) {
                              if (data.category == 'Z') {
                                return ColorConstants.logoLeafColor;
                              } else if (data.category == 'R') {
                                return ColorConstants.yellowFromCoinColor;
                              } else if (data.category == 'O') {
                                return ColorConstants.lightMainThemeColor;
                              }
                              return ColorConstants.dartMainThemeColor;
                            },
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.inside,
                              connectorLineSettings: ConnectorLineSettings(
                                  type: ConnectorType.curve),
                              textStyle: TextStyle(
                                  fontSize: 10.0, color: Colors.black),
                            ),
                            dataLabelMapper: (ChartTransactionsData data, _) =>
                                data.category,
                          ),
                        ],
                      ),
                    );

                    Widget balanceContainer = Container(
                      height: 50.0,
                      width: MediaQuery.of(context).size.width / 2.1,
                      decoration: BoxDecoration(
                          //border: Border.all(),
                          borderRadius: BorderRadius.circular(15.0),
                          color: ColorConstants.dartMainThemeColor),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(summary.income - summary.expenses).toStringAsFixed(2)} zł',
                              style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                    return Column(
                      children: [
                        Row(
                          children: [
                            if (chartData.isNotEmpty)
                              Column(
                                children: [
                                  // TODO l10n
                                  const Text('Wydatki'),
                                  chartsContainer,
                                ],
                              ),
                            const Spacer(),
                            Column(
                              children: [
                                // TODO l10n
                                const Text('Saldo'),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                balanceContainer,
                              ],
                            ),
                          ],
                        ),
                        //Spacer(),
                        const SizedBox(
                          height: 25.0,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: transactions.map((transaction) {
                              return Dismissible(
                                key: Key(transaction.documentId),
                                onDismissed: (direction) {
                                  FirebaseCloudTransactionStorage()
                                      .deleteTransactionDetails(
                                          documentId: transaction.documentId);
                                },
                                background: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const SizedBox(width: 20.0),
                                    Icon(
                                      Icons.delete,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(
                                      'Przesuń, aby usunąć',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    top: 15.0,
                                  ),
                                  height: 100.0,
                                  decoration: BoxDecoration(
                                    color: ColorConstants.lightMainThemeColor,
                                    border: Border.all(
                                        color:
                                            ColorConstants.dartMainThemeColor),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: ListTile(
                                    minLeadingWidth: 0.0,
                                    minVerticalPadding: 0.0,
                                    contentPadding: const EdgeInsets.only(
                                        bottom: 16.0,
                                        top: 8.0,
                                        left: 16.0,
                                        right: 16.0),
                                    dense: true,
                                    leading: SizedBox(
                                      width: 50.0,
                                      height: double.infinity,
                                      child: transactionTypeImages[
                                                      typeFromString(
                                                          transaction.type)]
                                                  ?.assetName !=
                                              null
                                          ? Image.asset(
                                              transactionTypeImages[
                                                      typeFromString(
                                                          transaction.type)]!
                                                  .assetName,
                                              width: 50.0,
                                              height: 50.0,
                                            )
                                          : const Icon(Icons.error),
                                    ),
                                    title: Text(
                                      capitalize(typeToString(
                                          typeFromString(transaction.type))),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                    subtitle:
                                        //Text(transaction.description ?? 'Brak opisu'),
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.description != null &&
                                                  transaction
                                                      .description!.isNotEmpty
                                              ? transaction.description!
                                              : 'Brak opisu',
                                        ),
                                        Text(DateFormat('dd-MM-yyyy').format(
                                            transaction.date.toLocal())),
                                      ],
                                    ),
                                    trailing: Text(
                                      //TODO l10n
                                      '${transaction.amount.toStringAsFixed(2)} zł',
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (transactions.isEmpty)
                          const Center(
                            child: Text('Brak transakcji'),
                          )
                      ],
                    );
                  }
                },
              ),
              const Spacer(),
              SizedBox(
                //width: 100,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewTransaction(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
              const SizedBox(
                height: 25.0,
              )
            ],
          ),
        ),
      ),
    );
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _loadUserDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDetailsCollection =
            FirebaseFirestore.instance.collection('userDetails');
        final snapshot = await userDetailsCollection
            .where('user_id', isEqualTo: user.uid)
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _userDetails = CloudUserDetails.fromSnapshot(snapshot.docs.first);
          });
        } else {}
      }
    } catch (error) {
      //TODO l10n
      log('Błąd podczas pobierania danych użytkownika: $error');
    }
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

  String typeToString(TransactionType type) {
    switch (type) {
      case TransactionType.groceries:
        return 'Zakupy';
      case TransactionType.restaurant:
        return 'Restauracja';
      case TransactionType.clothes:
        return 'Odzież';
      case TransactionType.salary:
        return 'Przychody';
      default:
        throw ArgumentError('Nieznany typ transakcji: $type');
    }
  }

  String typeToStringOnChart(TransactionType type) {
    switch (type) {
      case TransactionType.groceries:
        return 'Z';
      case TransactionType.restaurant:
        return 'R';
      case TransactionType.clothes:
        return 'O';
      case TransactionType.salary:
        return 'P';
      default:
        throw ArgumentError('Nieznany typ transakcji: $type');
    }
  }

  void updateChartData(List<CloudTransactionDetails> transactions) {
    chartData = [];
    Map<TransactionType, double> categoryMap = {};

    for (var transaction in transactions) {
      if (typeFromString(transaction.type) != TransactionType.salary) {
        categoryMap.update(
          typeFromString(transaction.type),
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    categoryMap.forEach((type, amount) {
      chartData.add(
        ChartTransactionsData(typeToStringOnChart(type), amount),
      );
    });
  }
}

class ChartTransactionsData {
  ChartTransactionsData(this.category, this.amount);

  final String category;
  final double amount;
}
