// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

class SMSDialog {
  const SMSDialog._(this.context);

  factory SMSDialog.of(BuildContext context) {
    return SMSDialog._(context);
  }

  final BuildContext context;

  Future<String?> show() async {
    return getSmsCodeFromUser(context);
  }

  static Future<String?> getSmsCodeFromUser(BuildContext context) async {
    String? smsCode;

    // Update the UI - wait for the user to enter the SMS code
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('SMS code:'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Sign in'),
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
