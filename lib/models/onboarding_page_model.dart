import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final List<String> features;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
    required this.features,
  });
}