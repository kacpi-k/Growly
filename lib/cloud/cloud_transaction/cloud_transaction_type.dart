import 'package:flutter/material.dart';

enum TransactionType { groceries, restaurant, salary, clothes }

Map<TransactionType, AssetImage> transactionTypeImages = {
  TransactionType.groceries: const AssetImage('assets/grocery_icon.png'),
  TransactionType.restaurant: const AssetImage('assets/restaurant_icon.png'),
  TransactionType.salary: const AssetImage('assets/salary_icon.png'),
  TransactionType.clothes: const AssetImage('assets/clothes_icon.png'),
};
