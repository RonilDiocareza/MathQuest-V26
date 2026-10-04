import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;

  const CustomButton({required this.text, this.onPressed, this.width, super.key});

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = width ?? 200;

    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey : Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: onPressed == null ? 0 : 8,
          minimumSize: Size(buttonWidth, 50),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: onPressed == null ? Colors.white70 : Colors.white,
          ),
        ),
      ),
    );
  }
}
