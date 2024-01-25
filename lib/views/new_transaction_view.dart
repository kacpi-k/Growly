import 'dart:developer';

import 'package:budget_planner_racka/auth/auth_service.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/cloud_transaction_type.dart';
import 'package:budget_planner_racka/cloud/cloud_transaction/firebase_cloud_transaction_storage.dart';
import 'package:budget_planner_racka/utilities/generics/get_argument.dart';
import 'package:flutter/material.dart';

class NewTransaction extends StatefulWidget {
  const NewTransaction({super.key});

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  TransactionType _selectedType = TransactionType.groceries;
  bool _dataInitialized = false;
  bool _isSaved = false;
  CloudTransactionDetails? _transactionDetails;

  late final TextEditingController _descriptionTextController;
  late final TextEditingController _amountTextController;
  late final FirebaseCloudTransactionStorage _transactionDetailsService;

  @override
  void initState() {
    _descriptionTextController = TextEditingController();
    _amountTextController = TextEditingController();
    _transactionDetailsService = FirebaseCloudTransactionStorage();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataInitialized) {
      createOrGetTransactionDetails(context);
      _dataInitialized = true;
    }
  }

  Future<CloudTransactionDetails> createOrGetTransactionDetails(
      BuildContext context) async {
    final widgetTransactionDetails =
        context.getArgument<CloudTransactionDetails>();
    if (widgetTransactionDetails != null) {
      log('transaction get');
      _transactionDetails = widgetTransactionDetails;
      _descriptionTextController.text = widgetTransactionDetails.description!;
      _amountTextController.text = widgetTransactionDetails.amount.toString();
      return widgetTransactionDetails;
    }

    log('transaction create');
    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;
    final newTransactionDetails = await _transactionDetailsService
        .createNewTransaction(ownerUserId: userId);
    _transactionDetails = newTransactionDetails;
    return newTransactionDetails;
  }

  void _deleteTransactionDetailsIfAmountIsEmpty() {
    final transactionDetails = _transactionDetails;
    log('transaction delete before if');
    if (_amountTextController.text.isEmpty ||
        double.parse(_amountTextController.text) <= 0 ||
        !_isSaved) {
      log('transaction delete');
      _transactionDetailsService.deleteTransactionDetails(
          documentId: transactionDetails!.documentId);
    }
  }

  void _saveTransactionDetailsIfAmountIsNotEmpty() async {
    final transactionDetails = _transactionDetails;
    final description = _descriptionTextController.text;
    final amount = _amountTextController.text;
    if (amount.isNotEmpty && transactionDetails != null && _isSaved) {
      log('transaction save');
      final doubleAmount = double.parse(_amountTextController.text);
      await _transactionDetailsService.updateTransactionDetails(
        documentId: transactionDetails.documentId,
        type: _selectedType.toString(),
        icon: transactionTypeImages[_selectedType]!.toString(),
        description: description,
        amount: doubleAmount,
        date: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _deleteTransactionDetailsIfAmountIsEmpty();
    _descriptionTextController.dispose();
    _amountTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          // TODO l10n
          title: const Text('Dodaj transakcję'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //TODO l10n
              const Text('Rodzaj'),
              DropdownButton<TransactionType>(
                value: _selectedType,
                onChanged: (TransactionType? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                items: TransactionType.values.map((type) {
                  return DropdownMenuItem<TransactionType>(
                    value: type,
                    child: Row(
                      children: [
                        Image.asset(
                          transactionTypeImages[type]!.assetName,
                          width: 24.0,
                          height: 24.0,
                        ),
                        const SizedBox(
                          width: 12.0,
                        ),
                        Text(typeToString(type)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              TextField(
                controller: _descriptionTextController,
                maxLength: 64,
                maxLines: null,
                decoration:
                    //TODO l10n
                    const InputDecoration(labelText: 'Opis (opcjonalnie)'),
              ),
              TextField(
                controller: _amountTextController,
                //TODO l10n
                decoration: const InputDecoration(labelText: 'Kwota'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.contains(',')) {
                    _amountTextController.value = TextEditingValue(
                      text: value.replaceAll(',', '.'),
                      selection: TextSelection.fromPosition(
                        TextPosition(offset: value.length),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(
                height: 25.0,
              ),
              Center(
                child: SizedBox(
                  width: 150.0,
                  child: ElevatedButton(
                    onPressed: () {
                      _isSaved = true;
                      _saveTransactionDetailsIfAmountIsNotEmpty();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Dodaj', //TODO l10n
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
