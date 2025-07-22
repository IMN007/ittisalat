import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'chat_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firebase = FirebaseService();
  final identityController = TextEditingController();
  final phoneController = TextEditingController();
  bool isRegistering = false;
  String? error;

  Future<void> _register() async {
    final identity = identityController.text.trim();
    final phone = phoneController.text.trim();

    if (identity.isEmpty || phone.isEmpty) {
      setState(() => error = '🛑 Ange både användarnamn och telefonnummer');
      return;
    }

    setState(() {
      isRegistering = true;
      error = null;
    });

    try {
      await firebase.registerUser(phone, identity);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(userIdentity: identity),
        ),
      );
    } catch (e) {
      setState(() {
        error = '🚫 Registrering misslyckades: $e';
        isRegistering = false;
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
      appBar: AppBar(title: const Text('👤 Registrera användare')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Välj ett användarnamn som du vill bli igenkänd med. Det kan innehålla bokstäver, siffror och arabiska tecken.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: identityController,
              decoration: const InputDecoration(
                labelText: '🆔 Användarnamn',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '📱 Telefonnummer (lagras, används ej)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isRegistering ? null : _register,
              child: Text(isRegistering ? 'Registrerar...' : 'Registrera'),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
