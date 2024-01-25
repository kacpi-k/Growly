import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

@immutable
class CloudTransactionDetails {
  final String documentId;
  final String userId;
  final String type;
  final String icon;
  final String? description;
  final double amount;
  final DateTime date;

  const CloudTransactionDetails({
    required this.documentId,
    required this.userId,
    required this.type,
    required this.icon,
    this.description,
    required this.amount,
    required this.date,
  });

  CloudTransactionDetails.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        userId = snapshot.data()![ownerUserIdFieldName],
        type = snapshot.data()![transactionTypeFieldName],
        icon = snapshot.data()![iconFieldName],
        description = snapshot.data()![descriptionFieldName],
        amount = snapshot.data()![amountFieldName],
        date = (snapshot.data()![dateFieldName] as Timestamp).toDate();
}
