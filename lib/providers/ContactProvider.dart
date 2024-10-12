import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  List<Contact> get contacts => _contacts;

  ContactProvider() {
    _getContactsPermission();
  }

  Future<void> _getContactsPermission() async {
    PermissionStatus permissionStatus = await Permission.contacts.status;

    if (!permissionStatus.isGranted) {
      permissionStatus = await Permission.contacts.request();
    }

    if (permissionStatus.isGranted) {
      _fetchContacts();
    }
  }

  Future<void> _fetchContacts() async {
    try {
      Iterable<Contact> contactsList = await ContactsService.getContacts();
      _contacts = contactsList.toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }
    String? getContactName(String phoneNumber) {
    for (var contact in _contacts) {
      if (contact.phones != null) {
        for (var phone in contact.phones!) {
          if (phone.value != null && phone.value!.contains(phoneNumber)) {
            return contact.displayName;
          }
        }
      }
    }
    return null;
  }
}
