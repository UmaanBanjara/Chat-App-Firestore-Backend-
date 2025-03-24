import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data/models/user_model.dart';
import 'package:flutter_application_1/data/service/base_repo.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactRepository extends BaseRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Get the current user's ID
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Request permission to access contacts
  Future<bool> requestContactsPermission() async {
    return await FlutterContacts.requestPermission();
  }

  // Fetch registered contacts from Firestore
  Future<List<Map<String, dynamic>>> getRegisteredContacts() async {
    try {
      // Check if permission is granted
      bool hasPermission = await requestContactsPermission();
      if (!hasPermission) return [];

      // Fetch contacts from the device
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      // Filter out contacts with no phone numbers
      final validContacts = contacts.where((contact) => 
        contact.phones.isNotEmpty && contact.phones.first.number.isNotEmpty
      ).toList();

      if (validContacts.isEmpty) return [];

      // Normalize contact numbers
      final phoneNumbers = validContacts.map((contact) {
        String rawNumber = contact.phones.first.number;
        String phoneNumber = rawNumber
            .replaceAll(RegExp(r'[^0-9]'), '') // Remove non-numeric characters
            .replaceFirst(RegExp(r'^977'), '') // Remove country code if present (Nepal)
            .replaceFirst(RegExp(r'^0'), ''); // Remove leading zero

        // Keep only the last 10 digits for consistency
        if (phoneNumber.length > 10) {
          phoneNumber = phoneNumber.substring(phoneNumber.length - 10);
        }

        return {
          'name': contact.displayName,
          'phoneNumber': phoneNumber,
          'photo': contact.photo,
        };
      }).toList();

      // Fetch registered users from Firestore
      final usersSnapshot = await firestore.collection('users').get();
      if (usersSnapshot.docs.isEmpty) return [];

      // Normalize user phone numbers
      final registeredUsers = usersSnapshot.docs.map((doc) {
        final user = UserModel.fromFirestore(doc);
        String userPhone = user.phoneNumber
            .replaceAll(RegExp(r'[^0-9]'), '')
            .replaceFirst(RegExp(r'^977'), '')
            .replaceFirst(RegExp(r'^0'), '');

        if (userPhone.length > 10) {
          userPhone = userPhone.substring(userPhone.length - 10);
        }

        return user.copyWith(phoneNumber: userPhone);
      }).toList();

      // Debug logs
      print('Contact numbers: ${phoneNumbers.map((e) => e['phoneNumber'])}');
      print('User numbers: ${registeredUsers.map((e) => e.phoneNumber)}');

      // Match contacts with registered users
      return phoneNumbers.where((contact) {
        return registeredUsers.any((user) =>
            user.phoneNumber == contact['phoneNumber'] &&
            user.uid != currentUserId);
      }).map((contact) {
        final user = registeredUsers.firstWhere(
            (u) => u.phoneNumber == contact['phoneNumber']);
        return {
          'id': user.uid,
          'name': contact['name'],
          'phoneNumber': contact['phoneNumber'],
          'photo': contact['photo'],
        };
      }).toList();

    } catch (e, stack) {
      // Print error stack trace
      print('Error getting contacts: $e');
      print(stack);
      return [];
    }
  }
}
