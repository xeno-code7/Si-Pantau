import 'package:flutter/material.dart';

Color statusColor(String status) {
  if (status == "danger") return Colors.red;
  if (status == "warning") return Colors.orange;
  return Colors.green;
}
