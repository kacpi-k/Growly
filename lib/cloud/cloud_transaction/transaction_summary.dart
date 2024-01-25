import 'dart:developer';

import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_type.dart';

class TransactionSummary {
  late double income;
  late double expenses;

  TransactionSummary() {
    income = 0.0;
    expenses = 0.0;
  }

  void processTransaction(CloudTransactionDetails transaction) {
    if (transaction.type == TransactionType.salary.toString()) {
      income += transaction.amount;
    } else {
      expenses += transaction.amount;
    }
    log('salary ${income.toString()}');
    log('expenses ${expenses.toString()}');
  }

  void resetSummary() {
    income = 0.0;
    expenses = 0.0;
  }
}
