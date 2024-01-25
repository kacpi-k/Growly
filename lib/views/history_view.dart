// import 'dart:developer';

import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_type.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/firebase_cloud_transaction_storage.dart';
import 'package:budget_planner_racka/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  Stream<Iterable<CloudTransactionDetails>>? transactionStream;
  List<CloudTransactionDetails> currentTransactions = [];
  int transactionsLimit = 10;
  int loadedTransactions = 0;
  DateTime? lastTransactionDate;
  int _totalTransactionCount = 0;

  @override
  void initState() {
    transactionStream =
        FirebaseCloudTransactionStorage().getAllTransactionDetails(
      ownerUserId: FirebaseAuth.instance.currentUser!.uid.toString(),
    );
    loadTransactions();
    super.initState();
  }

  @override
  void dispose() {
    loadedTransactions = 10;
    super.dispose();
  }

  void loadTransactions() {
    transactionStream?.listen((snapshot) {
      setState(() {
        currentTransactions = snapshot.toList();
        if (currentTransactions.isNotEmpty) {
          lastTransactionDate = currentTransactions.last.date;
        }
        loadedTransactions = transactionsLimit;
      });
    });
  }

  void loadMoreTransactions() async {
    FirebaseCloudTransactionStorage transactionDetails =
        FirebaseCloudTransactionStorage();
    if (lastTransactionDate != null) {
      FirebaseCloudTransactionStorage()
          .getPaginatedTransactionDetailsFromDate(
        ownerUserId: FirebaseAuth.instance.currentUser!.uid.toString(),
        lastTransactionDate: lastTransactionDate!,
        limit: transactionsLimit,
      )
          .listen((nextTransactions) async {
        int totalTransactionsCount =
            await transactionDetails.getTotalTransactionsCount(
                ownerUserId: FirebaseAuth.instance.currentUser!.uid.toString());
        _totalTransactionCount = totalTransactionsCount;
        setState(() {
          currentTransactions.addAll(nextTransactions);
          lastTransactionDate = currentTransactions.last.date;

          if (totalTransactionsCount < loadedTransactions + transactionsLimit) {
            loadedTransactions += totalTransactionsCount - loadedTransactions;
          } else {
            loadedTransactions += transactionsLimit;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // TODO l10n
        title: const Text('Twoje transakcje'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: StreamBuilder<Iterable<CloudTransactionDetails>>(
          stream: transactionStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator()); // Możesz również zwrócić pusty kontener tymczasowo.
            } else if (snapshot.hasError) {
              return Text('Błąd: ${snapshot.error}');
            } else {
              List<CloudTransactionDetails> transactions = currentTransactions;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: loadedTransactions + 1,
                      itemBuilder: (context, index) {
                        if (index == loadedTransactions) {
                          if (_totalTransactionCount == 0 ||
                              loadedTransactions < _totalTransactionCount) {
                            return Container(
                              margin: const EdgeInsets.only(
                                  top: 10.0, bottom: 10.0),
                              child: TextButton(
                                onPressed: loadMoreTransactions,
                                // TODO l10n
                                child: const Text('Załaduj wiecej'),
                              ),
                            );
                          } else {
                            //log('currentTransactions.length: ${currentTransactions.length}, _totalTransactionCount $_totalTransactionCount ');
                            return Container(
                              margin: const EdgeInsets.only(
                                  top: 10.0, bottom: 20.0),
                              child: const Center(
                                // TODO l10n
                                child: Text('To już wszystko!'),
                              ),
                            );
                          }
                        }
                        CloudTransactionDetails transaction =
                            transactions[index];
                        return Dismissible(
                          key: Key(transaction.documentId),
                          onDismissed: (direction) {
                            FirebaseCloudTransactionStorage()
                                .deleteTransactionDetails(
                                    documentId: transaction.documentId);
                          },
                          background: Container(
                            color: Colors.white,
                            child: Row(
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
                                  // TODO l10n
                                  'Przesuń, aby usunąć',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsetsDirectional.symmetric(
                              vertical: 10.0,
                            ),
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: ColorConstants.lightMainThemeColor,
                              border: Border.all(
                                color: ColorConstants.dartMainThemeColor,
                              ),
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
                                child: transactionTypeImages[typeFromString(
                                                transaction.type)]
                                            ?.assetName !=
                                        null
                                    ? Image.asset(
                                        transactionTypeImages[typeFromString(
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.description != null &&
                                            transaction.description!.isNotEmpty
                                        ? transaction.description!
                                        // TODO l10n
                                        : 'Brak opisu',
                                  ),
                                  Text(
                                    DateFormat('dd-MM-yyyy').format(
                                      transaction.date.toLocal(),
                                    ),
                                  ),
                                ],
                              ),
                              // TODO l10n
                              trailing: Text(
                                '${transaction.amount.toStringAsFixed(2)} zł',
                                style: const TextStyle(
                                  fontSize: 15.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
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
        return 'Restauracja';
      case TransactionType.clothes:
        return 'Odzież';
      case TransactionType.salary:
        return 'Przychody';
      default:
        throw ArgumentError('Nieznany typ transakcji: $type');
    }
  }
}
