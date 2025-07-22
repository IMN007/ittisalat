import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String authCredential = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    print('Försöker autentisera: Användarnamn=$authCredential, Lösenord=${password.isNotEmpty ? "******" : "Tomt"}'); // Debug-utskrift

    try {
      if (_isLogin) {
        print('Försöker logga in...'); // Debug-utskrift
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: authCredential,
          password: password,
        );
        print('Inloggning lyckades!'); // Debug-utskrift
      } else {
        print('Försöker registrera...'); // Debug-utskrift
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: authCredential,
          password: password,
        );
        print('Registrering lyckades! Användar-UID: ${userCredential.user?.uid}'); // Debug-utskrift

        // Försök att spara användarnamnet i Firestore
        if (userCredential.user != null) {
          print('Försöker spara användarprofil i Firestore...'); // Debug-utskrift
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': authCredential,
            'name': authCredential,
          });
          print('Användarprofil sparad i Firestore!'); // Debug-utskrift
        } else {
          print('Fel: Användarobjektet är null efter registrering.'); // Debug-utskrift
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException fångad: ${e.code}, Meddelande: ${e.message}'); // Debug-utskrift för fel
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Ingen användare hittades med det användarnamnet.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Fel lösenord angivet.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Användarnamnet används redan.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'Lösenordet är för svagt.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Ogiltigt användarnamn format. Användaren måste ha ett giltigt e-postformat (t.ex. "användare@domän.com").';
        } else {
          _errorMessage = 'Autentiseringsfel: ${e.message}';
        }
      });
    } catch (e) {
      print('Oväntat fel fångat: $e'); // Debug-utskrift för andra fel
      setState(() {
        _errorMessage = 'Ett oväntat fel uppstod: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        print('Autentiseringsprocessen avslutad. Laddningsindikator dold.'); // Debug-utskrift
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Logga in' : 'Registrera dig'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Användarnamn',
                  hintText: 'Ange ditt användarnamn (t.ex. "användare@domän.com")',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Lösenord',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_isLogin ? 'Logga in' : 'Registrera dig', style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _errorMessage = null;
                  });
                },
                child: Text(
                  _isLogin ? 'Har inget konto? Registrera dig här.' : 'Har redan ett konto? Logga in här.',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
