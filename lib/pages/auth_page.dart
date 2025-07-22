import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final identityController = TextEditingController();
  final phoneController = TextEditingController();
  bool isSaving = false;
  String errorMessage = '';

  final nameRegex = RegExp(r"^[\p{L}\s\-']+$", unicode: true);

  Future<void> registerUser() async {
    final identity = identityController.text.trim();
    final phone = phoneController.text.trim();

    print('🔍 Namn: $identity | Nummer: $phone');

    if (identity.isEmpty || !nameRegex.hasMatch(identity)) {
      setState(() => errorMessage = '🚫 Namn får bara innehålla bokstäver och mellanslag.');
      return;
    }

    if (!phone.startsWith('+46') || phone.length < 11) {
      setState(() => errorMessage = '📱 Nummer måste vara i format: +467XXXXXXXX');
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = '';
    });

    try {
      final ref = FirebaseFirestore.instance.collection('users');

      final snapshot = await ref.where('identity', isEqualTo: identity).get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          errorMessage = '❗ Namnet är redan registrerat.';
          isSaving = false;
        });
        return;
      }

      await ref.doc(phone).set({
        'identity': identity,
        'phone': phone,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userIdentity', identity);
      await prefs.setString('phoneNumber', phone);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(userIdentity: identity)),
      );
    } catch (e) {
      print('🔥 REGISTRERING FEL: $e');
      setState(() {
        errorMessage = '⚠️ Fel vid registrering. Försök igen.';
        isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    identityController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ITTISAL – Registrering')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skriv ett användarnamn och ditt nummer för att komma igång',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: identityController,
              decoration: const InputDecoration(labelText: 'Användarnamn'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefonnummer',
                hintText: '+467XXXXXXXX',
              ),
            ),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSaving ? null : registerUser,
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Fortsätt'),
            ),
          ],
        ),
      ),
    );
  }
}
