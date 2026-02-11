import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onOkPressed;

  const ErrorDialog({
    Key? key,
    required this.message,
    this.title,
    this.onOkPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title ?? 'Error',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          height: 1.4,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: onOkPressed ?? () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A651),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
