import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registrera en användare i Firestore
  /// Använder telefonnummer som dokument-ID.
  Future<void> registerUser(String phone, String identity) async {
    try {
      await _db.collection('users').doc(phone).set({
        'phone': phone,
        'identity': identity,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Användare $identity ($phone) registrerad i Firestore.');
    } catch (e) {
      print('❌ Fel vid registrering av användare $phone: $e');
      rethrow;
    }
  }

  /// Hämta alla registrerade användares telefonnummer (doc-IDs)
  /// Returnerar en lista med strängar.
  Future<List<String>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      final userPhones = snapshot.docs.map((doc) => doc.id).toList();
      print('✅ Hämtade ${userPhones.length} användare från Firestore.');
      return userPhones;
    } catch (e) {
      print('❌ Fel vid hämtning av alla användare: $e');
      return [];
    }
  }

  /// Hämta användarens identitet (namn/alias) baserat på telefonnummer.
  /// Returnerar identiteten som en sträng, eller null om användaren inte finns.
  Future<String?> getUserIdentity(String phone) async {
    try {
      final doc = await _db.collection('users').doc(phone).get();
      if (doc.exists) {
        final identity = doc['identity'] as String?;
        print('✅ Hämtade identitet för $phone: $identity');
        return identity;
      }
      print('ℹ️ Användare $phone hittades inte i Firestore.');
      return null;
    } catch (e) {
      print('❌ Fel vid hämtning av användaridentitet för $phone: $e');
      return null;
    }
  }

  /// Skicka WebRTC-offer till Firestore.
  /// Skapar eller uppdaterar ett samtalsdokument med offer-data.
  Future<void> sendOffer({
    required String callId,
    required String sdp,
    required String type,
    required String from,
    required String to,
  }) async {
    try {
      await _db.collection('calls').doc(callId).set({
        'offer': {
          'sdp': sdp,
          'type': type,
          'from': from,
          'to': to,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Offer skickat till Firestore för samtal $callId (från: $from, till: $to).');
    } catch (e) {
      print('❌ Fel vid sändning av offer för samtal $callId: $e');
      rethrow;
    }
  }

  /// Skicka WebRTC-answer till Firestore.
  /// Uppdaterar befintligt samtalsdokument med answer-data.
  Future<void> sendAnswer(String callId, Map<String, dynamic> answer) async {
    try {
      await _db.collection('calls').doc(callId).update({
        'answer': answer,
        'answerTimestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Answer skickat till Firestore för samtal $callId.');
    } catch (e) {
      print('❌ Fel vid sändning av answer för samtal $callId: $e');
      rethrow;
    }
  }

  /// Lägg till ICE-kandidat till en specifik sub-kollektion i Firestore.
  /// 'type' bör vara antingen 'callerCandidates' eller 'calleeCandidates'.
  Future<void> addCandidate(String callId, String collectionType, Map<String, dynamic> candidate) async {
    try {
      await _db
          .collection('calls')
          .doc(callId)
          .collection(collectionType) // Använder den angivna sub-kollektionstypen
          .add(candidate);
      print('✅ ICE-kandidat tillagd i "$collectionType" för samtal $callId.');
    } catch (e) {
      print('❌ Fel vid tillägg av ICE-kandidat i "$collectionType" för samtal $callId: $e');
      rethrow;
    }
  }

  /// Avböj samtalet (radera call-dokumentet).
  /// Detta är en explicit avböjningsmekanism.
  Future<void> declineCall(String callId) async {
    try {
      await _db.collection('calls').doc(callId).delete();
      print('✅ Samtal $callId avböjt och borttaget från Firebase.');
    } catch (e) {
      print('❌ Fel vid avböjning/borttagning av samtal $callId: $e');
      rethrow;
    }
  }

  /// Avsluta samtalet (radera call-dokumentet)
  /// Denna metod är nu mer generisk för att städa upp ett samtal.
  Future<void> endCall(String callId) async {
    try {
      // För att säkerställa att även subkollektioner med kandidater tas bort,
      // behövs eventuellt en Cloud Function om de är stora, annars räcker delete().
      // För småskaligt test, är delete() oftast tillräckligt.
      await _db.collection('calls').doc(callId).delete();
      print('✅ Samtal $callId avslutat och borttaget från Firebase.');
    } catch (e) {
      print('❌ Fel vid avslutning/borttagning av samtal $callId: $e');
      rethrow;
    }
  }
}