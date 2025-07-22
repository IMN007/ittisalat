import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/incoming_call_dialog.dart';
import '../pages/call_page.dart';
import '../services/firebase_service.dart';

class ChatPage extends StatefulWidget {
  final String userIdentity;

  const ChatPage({required this.userIdentity, super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final firebase = FirebaseService();
  List<Map<String, String>> availableUsers = [];
  String? _activeIncomingCallId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _listenForCalls();
  }

  Future<void> _loadUsers() async {
    final phones = await firebase.getAllUsers();
    final result = <Map<String, String>>[];

    for (final phone in phones) {
      final identity = await firebase.getUserIdentity(phone);
      if (identity != null && identity != widget.userIdentity) {
        result.add({'identity': identity, 'phone': phone});
      }
    }

    setState(() => availableUsers = result);
  }

  void _listenForCalls() {
    FirebaseFirestore.instance.collection('calls').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final offer = data['offer'];

        final from = offer?['from'];
        final to = offer?['to'];

        final callId = from != null && to != null
            ? from.compareTo(to) < 0 ? '$from|$to' : '$to|$from'
            : null;

        final isIncomingToMe =
            offer != null &&
            to == widget.userIdentity &&
            from != widget.userIdentity;

        if (isIncomingToMe && callId != null && _activeIncomingCallId != callId) {
          print('📥 Inkommande samtal till ${widget.userIdentity} från $from');
          _activeIncomingCallId = callId;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showIncomingDialog(from!, callId);
          });
        }
      }
    });
  }

  void _startCall(String peerIdentity) {
    final callId = widget.userIdentity.compareTo(peerIdentity) < 0
        ? '${widget.userIdentity}|$peerIdentity'
        : '$peerIdentity|${widget.userIdentity}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          myIdentity: widget.userIdentity,
          peerIdentity: peerIdentity,
          isCaller: true,
        ),
      ),
    );
  }

  void _showIncomingDialog(String fromIdentity, String callId) {
    showDialog(
      context: context,
      builder: (_) => IncomingCallDialog(
        callerName: fromIdentity,
        myIdentity: widget.userIdentity,
        peerIdentity: fromIdentity,
        onDecline: () {
          firebase.endCall(callId);
          _activeIncomingCallId = null;
        },
      ),
    ).then((_) {
      _activeIncomingCallId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ITTISAL – Kontakter')),
      body: ListView.builder(
        itemCount: availableUsers.length,
        itemBuilder: (_, index) {
          final user = availableUsers[index];
          return ListTile(
            title: Text('👤 ${user['identity']}'),
            subtitle: Text('📱 ${user['phone']}'),
            trailing: ElevatedButton(
              onPressed: () => _startCall(user['identity']!),
              child: const Text('Ring'),
            ),
          );
        },
      ),
    );
  }
}
