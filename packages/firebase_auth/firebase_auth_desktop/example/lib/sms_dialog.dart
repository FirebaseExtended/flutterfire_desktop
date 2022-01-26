// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

class ExampleDialog {
  ExampleDialog._(this.context);

  factory ExampleDialog.of(BuildContext context) {
    return ExampleDialog._(context);
  }

  final BuildContext context;

  late String title;
  late String buttonLabel;

  Future<String?> show(String title, String buttonLabel) async {
    this.title = title;
    this.buttonLabel = buttonLabel;

    return getSmsCodeFromUser(context);
  }

  Future<String?> getSmsCodeFromUser(BuildContext context) async {
    String? smsCode;

    // Update the UI - wait for the user to enter the SMS code
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(buttonLabel),
            ),
            OutlinedButton(
              onPressed: () {
                smsCode = null;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
          content: Container(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (value) {
                smsCode = value;
              },
              textAlign: TextAlign.center,
              autofocus: true,
            ),
          ),
        );
      },
    );

    return smsCode;
  }
}
