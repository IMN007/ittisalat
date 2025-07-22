import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ittisal2/auth_screen.dart'; // Importerar den nya autentiseringsskärmen
// import 'firebase_options.dart'; // Uncommenta denna rad om du har en firebase_options.dart-fil

void main() async {
  // Säkerställer att Flutter-bindningarna är initialiserade innan Firebase används.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiserar Firebase för appen.
  await Firebase.initializeApp(
    // Om du har en firebase_options.dart-fil (genererad av FlutterFire CLI),
    // uncommenta raden nedan för att använda plattformsspecifika alternativ.
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  // Kör Flutter-appen.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ittisal', // Appens titel
      theme: ThemeData(
        primarySwatch: Colors.blue, // Appens primära färgtema
        visualDensity: VisualDensity.adaptivePlatformDensity, // Anpassar densiteten för olika plattformar
      ),
      // Använder en StreamBuilder för att lyssna på ändringar i Firebase Authentication-tillståndet.
      // Detta gör att appen automatiskt växlar mellan inloggningsskärm och huvudskärm.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Lyssnar på användarens inloggningsstatus
        builder: (context, snapshot) {
          // Om anslutningen väntar (t.ex. vid appstart medan Firebase kontrollerar inloggning).
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Visar en laddningsindikator.
          }
          // Om det finns data (dvs. en användare är inloggad).
          if (snapshot.hasData) {
            // Användaren är inloggad, visa huvudskärmen (MyHomePage).
            return const MyHomePage(title: 'ITTISASL _ KONTAKTER');
          } else {
            // Användaren är inte inloggad, visa autentiseringsskärmen (AuthScreen).
            return const AuthScreen();
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title; // Titeln för huvudskärmen

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  User? _currentUser; // Den för närvarande inloggade Firebase-användaren
  String _currentUserName = 'Laddar namn...'; // Visningsnamnet för den inloggade användaren

  @override
  void initState() {
    super.initState();
    // Lyssnar på ändringar i inloggningsstatus för att uppdatera UI.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _currentUser = user; // Uppdaterar den aktuella användaren
        _fetchCurrentUserName(); // Hämtar användarens namn
      } else {
        setState(() {
          _currentUser = null; // Ställer in användaren som null om utloggad
          _currentUserName = 'Inte inloggad'; // Uppdaterar visningsnamnet
        });
      }
    });
    // Hämtar den initiala användaren vid widgetens start.
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchCurrentUserName();
  }

  // Funktion för att hämta den inloggade användarens namn från Firebase eller Firestore.
  Future<void> _fetchCurrentUserName() async {
    if (_currentUser != null) {
      // Försöker först använda display name från Firebase Authentication (om det finns).
      if (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
        setState(() {
          _currentUserName = _currentUser!.displayName!;
        });
      } else {
        // Om display name saknas, försöker hämta namn från Firestore-profil.
        // Antar att användarprofiler lagras i en 'users' samling med UID som dokument-ID.
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            // Prioriterar 'name'-fältet från Firestore, annars 'email'-fältet.
            if (userData.containsKey('name') && userData['name'] != null) {
              setState(() {
                _currentUserName = userData['name'];
              });
            } else if (_currentUser!.email != null) {
              setState(() {
                _currentUserName = _currentUser!.email!;
              });
            }
          } else if (_currentUser!.email != null) {
            setState(() {
              _currentUserName = _currentUser!.email!;
            });
          }
        } catch (e) {
          // Loggar fel vid hämtning av användarnamn från Firestore.
          print("Fel vid hämtning av användarnamn från Firestore: $e");
          // Fallback till e-post om Firestore-hämtning misslyckas.
          if (_currentUser!.email != null) {
            setState(() {
              _currentUserName = _currentUser!.email!;
            });
          }
        }
      }
    } else {
      // Om ingen användare är inloggad.
      setState(() {
        _currentUserName = 'Inte inloggad';
      });
    }
  }

  // Funktion för att radera en kontakt från Firestore.
  Future<void> _deleteContact(String contactUid, String contactName) async {
    // Visar en bekräftelsedialog för användaren.
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Användaren måste trycka på en knapp för att stänga.
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Radera kontakt?'),
          content: Text('Är du säker på att du vill radera $contactName från dina kontakter?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Avbryt'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Stänger dialogen.
              },
            ),
            TextButton(
              child: const Text('Radera'),
              onPressed: () async {
                try {
                  // Raderar dokumentet för kontakten från 'users' samlingen i Firestore.
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(contactUid)
                      .delete();
                  // Visar ett meddelande om att raderingen lyckades.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$contactName raderad framgångsrikt.')),
                  );
                } catch (e) {
                  // Visar ett felmeddelande om raderingen misslyckades.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kunde inte radera $contactName: $e')),
                  );
                } finally {
                  Navigator.of(dialogContext).pop(); // Stänger dialogen.
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Appbarens titel
        backgroundColor: Theme.of(context).primaryColor, // Bakgrundsfärg för appbaren
        elevation: 4, // Skugga under appbaren
        actions: [ // Åtgärder/knappar i appbaren
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), // Ikon för utloggning
            tooltip: 'Logga ut', // Verktygstips vid hovring
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Loggar ut användaren från Firebase
              // Visar ett meddelande om utloggning.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Du är utloggad.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visar den inloggade användarens namn.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Inloggad som: $_currentUserName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16), // En avdelare
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Hämtar alla användare från 'users' samlingen i Firestore i realtid.
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                // Om det finns ett fel vid laddning av kontakter.
                if (snapshot.hasError) {
                  return Center(child: Text('Fel vid laddning av kontakter: ${snapshot.error}'));
                }
                // Om anslutningen väntar på data.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); // Visar laddningsindikator.
                }

                // Filtrerar bort den nuvarande inloggade användaren från kontaktlistan.
                final contacts = snapshot.data!.docs.where((doc) => doc.id != _currentUser?.uid).toList();

                // Om inga andra kontakter hittades.
                if (contacts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Inga andra kontakter hittades. Lägg till nya eller se till att andra användare är registrerade.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                // Bygger en lista med kontakter.
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final contactData = contact.data() as Map<String, dynamic>;
                    // Försöker hämta 'name', annars 'email', annars 'Okänt namn'.
                    final contactName = contactData['name'] ?? contactData['email'] ?? 'Okänt namn';
                    final contactUid = contact.id; // Kontaktens unika ID (UID)

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      elevation: 2, // Lägger till skugga för korten
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rundade hörn
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(
                          contactName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(contactData['email'] ?? 'Ingen e-post'), // Visar e-post om namn saknas
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Knapp för att ringa (exempel, funktion ej implementerad ännu)
                            IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              tooltip: 'Ring ${contactName}',
                              onPressed: () {
                                // TODO: Implementera samtalsfunktionalitet här
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ringer $contactName... (Funktion ej implementerad)')),
                                );
                              },
                            ),
                            // Knapp för att radera kontakt
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Radera ${contactName}',
                              onPressed: () => _deleteContact(contactUid, contactName),
                            ),
                          ],
                        ),
                        onTap: () {
                          // TODO: Implementera chatt- eller profilvy här
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Öppnar chatt med $contactName... (Funktion ej implementerad)')),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Flytande åtgärdsknapp för att lägga till ny kontakt (funktion ej implementerad ännu)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementera funktionalitet för att lägga till ny kontakt
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lägg till ny kontakt (funktion ej implementerad)')),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
