import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsPermissionButton extends StatefulWidget {
  @override
  _SmsPermissionButtonState createState() => _SmsPermissionButtonState();
}

class _SmsPermissionButtonState extends State<SmsPermissionButton> {
  void _askForPermission() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      var permission = await Permission.sms.request();
      if (permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permission Granted"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _askForPermission,
      child: Text("Ask For SMS Permission"),
    );
  }
}
