import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  final String? message;

  const LoadingDialog({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: key,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 10),
          Text(message!),
        ],
      ),
    );
  }
}
