import 'package:flutter/material.dart';

enum CategoryFlow { income, expense }

class CategoryModel {
  final String id;
  final String name;
  final CategoryFlow flow;
  final IconData icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.flow,
    required this.icon,
  });
}
