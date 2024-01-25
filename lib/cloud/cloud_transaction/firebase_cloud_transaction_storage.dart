import 'dart:developer';

import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_constants.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_exceptions.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseCloudTransactionStorage {
  final transactionDetails =
      FirebaseFirestore.instance.collection('transaction');

  static final FirebaseCloudTransactionStorage _shared =
      FirebaseCloudTransactionStorage._sharedInstance();
  FirebaseCloudTransactionStorage._sharedInstance();
  factory FirebaseCloudTransactionStorage() => _shared;

  Stream<Iterable<CloudTransactionDetails>> getAllTransactionDetails(
          {required String ownerUserId}) =>
      transactionDetails
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .orderBy(dateFieldName, descending: true)
          .snapshots()
          .map(
            (event) => event.docs.map(
              (doc) => CloudTransactionDetails.fromSnapshot(doc),
            ),
          );

  Stream<Iterable<CloudTransactionDetails>> getTransactionsForMonth({
    required String ownerUserId,
    required DateTime month,
  }) {
    DateTime startOfMonth = DateTime(month.year, month.month, 1);
    DateTime endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return transactionDetails
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .where(dateFieldName, isGreaterThanOrEqualTo: startOfMonth)
        .where(dateFieldName, isLessThanOrEqualTo: endOfMonth)
        .orderBy(dateFieldName, descending: true)
        .snapshots()
        .map(
          (event) => event.docs.map(
            (doc) => CloudTransactionDetails.fromSnapshot(doc),
          ),
        );
  }

  Stream<Iterable<CloudTransactionDetails>>
      getPaginatedTransactionDetailsFromDate({
    required String ownerUserId,
    required DateTime lastTransactionDate,
    required int limit,
  }) {
    return transactionDetails
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .where(dateFieldName, isLessThan: lastTransactionDate)
        .orderBy(dateFieldName, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (event) => event.docs
              .map((doc) => CloudTransactionDetails.fromSnapshot(doc)),
        );
  }

  Future<CloudTransactionDetails> createNewTransaction(
      {required String ownerUserId}) async {
    log('in createNewTransaction');
    final document = await transactionDetails.add(
      {
        ownerUserIdFieldName: ownerUserId,
        transactionTypeFieldName: TransactionType.groceries.toString(),
        iconFieldName: '',
        descriptionFieldName: '',
        amountFieldName: 0.0,
        dateFieldName: DateTime.now(),
      },
    );
    final fetchedTransactionDetails = await document.get();
    log('before return createNewTransactions');
    return CloudTransactionDetails(
      documentId: fetchedTransactionDetails.id,
      userId: ownerUserId,
      type: TransactionType.groceries.toString(),
      icon: Icons.abc.toString(),
      description: '',
      amount: 0.0,
      date: DateTime.now(),
    );
  }

  Future<void> deleteTransactionDetails({required String documentId}) async {
    try {
      await transactionDetails.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteTransactionDetailsException();
    }
  }

  Future<void> updateTransactionDetails({
    required String documentId,
    required String type,
    required String icon,
    String? description,
    required double amount,
    required DateTime date,
  }) async {
    try {
      await transactionDetails.doc(documentId).update({
        transactionTypeFieldName: type,
        iconFieldName: icon,
        descriptionFieldName: description,
        amountFieldName: amount,
        dateFieldName: date,
      });
    } catch (e) {
      throw CouldNotUpdateTransactionDetailsException();
    }
  }

  Future<int> getTotalTransactionsCount({required String ownerUserId}) async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await transactionDetails
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .get();

    return snapshot.size;
  }
}
