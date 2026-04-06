import 'package:flutter/material.dart';

class InputDecorate {  InputDecoration buildInputDecoration(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    suffixIcon: suffixIcon,
    labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
    floatingLabelStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
    filled: true,
    //fillColor: Colors.grey[200],
    fillColor: Colors.white.withValues(alpha: 0.3),
    contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: Colors.red.withValues(alpha: 0.6),
        width: 3,
      ),
    ),

    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 3,
      ),
    ),

    errorStyle: const TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.w500,
      fontSize: 16,
    ),
  );
}
}