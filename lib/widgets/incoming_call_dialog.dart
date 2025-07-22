import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Behåll denna import
import '../pages/call_page.dart';
// Importera FirebaseService för att kunna anropa declineCall
import '../services/firebase_service.dart'; // Antar att du har denna

class IncomingCallDialog extends StatefulWidget {
  final String callerName;
  final String myIdentity;
  final String peerIdentity;
  // onDecline callback är bra, men vi kommer också att hantera Firebase-logiken här
  final VoidCallback onDecline;

  const IncomingCallDialog({
    required this.callerName,
    required this.myIdentity,
    required this.peerIdentity,
    required this.onDecline, // Behåll denna för eventuell extern logik
    super.key,
  });

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog> {
  late final AudioPlayer _player;
  Timer? _timeoutTimer;
  int _countdown = 30;
  bool _cleanedUp = false; // Flagga för att förhindra dubbelstädning

  // FirebaseService instans för att kunna avböja samtalet i Firebase
  final FirebaseService _firebaseService = FirebaseService();

  // Beräkna callId här, precis som i CallPage för konsistens
  String get callId => widget.myIdentity.compareTo(widget.peerIdentity) < 0
      ? '${widget.myIdentity}|${widget.peerIdentity}'
      : '${widget.peerIdentity}|${widget.myIdentity}';

  @override
  void initState() {
    super.initState();

    print('🔔 IncomingCallDialog initieras för callId=$callId');

    _player = AudioPlayer();
    _player.setVolume(1.0);
    _player.setReleaseMode(ReleaseMode.loop);

    // Förbättrad felhantering för ringsignalen
    _player.play(AssetSource('sounds/ringtone.mp3')).catchError((e) {
      print('🎵 Ringsignal misslyckades att spela: $e');
      // Du kan lägga till en fallback här, t.ex. vibrera om ljudet misslyckas
      // HapticFeedback.vibrate();
    });

    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { // Lägg till mounted check för att förhindra fel om widgeten tas bort
        timer.cancel();
        return;
      }
      if (_countdown <= 0) {
        print('⏳ Timeout nådd – avvisar samtal');
        _handleDecline(); // Anropa hanteringsfunktionen
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _handleAccept() {
    if (_cleanedUp) return; // Förhindra dubbelkörning
    print('✅ Svara tryckt – startar CallPage');
    _cleanup(); // Städa upp ringsignal och timer

    // Navigera till CallPage. Se till att alla nödvändiga parametrar skickas.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          myIdentity: widget.myIdentity,
          peerIdentity: widget.peerIdentity,
          isCaller: false, // Mottagaren
        ),
      ),
    );
  }

  void _handleDecline() async { // Gör funktionen async
    if (_cleanedUp) return; // Förhindra dubbelkörning
    print('❌ Avslå tryckt – samtalet avslutas');
    _cleanup(); // Städa upp ringsignal och timer
    Navigator.pop(context); // Stäng dialogen

    // Anropa onDecline callback som skickades in (för t.ex. UI-uppdatering i ChatPage)
    widget.onDecline();

    // Ta bort samtalsdokumentet från Firebase när samtalet avböjs
    await _firebaseService.declineCall(callId); // Använd den nya declineCall-metoden
  }

  void _cleanup() {
    if (_cleanedUp) return; // Förhindra dubbelstädning
    _cleanedUp = true; // Markera som städad
    print('🧹 Stänger ringsignal och timer i dialog');
    _timeoutTimer?.cancel(); // Avbryt timern
    _player.stop().catchError((e) { // Lägg till felhantering för stop
      print('🎵 Fel vid stopp av ringsignal: $e');
    });
    _player.dispose().catchError((e) { // Lägg till felhantering för dispose
      print('🎵 Fel vid dispose av ringsignalspelare: $e');
    });
  }

  @override
  void dispose() {
    _cleanup(); // Säkerställ att resurser städas när dialogen stängs
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('📞 Samtal från ${widget.callerName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Vill du svara på samtalet?', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text(
            '⏱️ Automatisk avvisning om $_countdown sekunder',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _handleDecline,
          child: const Text('Avslå'),
        ),
        ElevatedButton(
          onPressed: _handleAccept,
          child: const Text('Svara'),
        ),
      ],
    );
  }
}