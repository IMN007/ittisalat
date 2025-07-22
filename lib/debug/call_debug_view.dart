import 'package:flutter/material.dart';

class CallDebugView extends StatelessWidget {
  final String callId;
  final String myPhone;
  final String peerPhone;
  final String status;
  final bool isCaller;
  final bool remoteDescriptionSet;
  final int iceSent;
  final int iceReceived;

  const CallDebugView({
    required this.callId,
    required this.myPhone,
    required this.peerPhone,
    required this.status,
    required this.isCaller,
    required this.remoteDescriptionSet,
    required this.iceSent,
    required this.iceReceived,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🛠️ Samtalsdebuggning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow('📞 Call ID:', callId),
            _infoRow('👤 Jag:', myPhone),
            _infoRow('👤 Motpart:', peerPhone),
            _infoRow('📡 Status:', status),
            _infoRow('📤 Uppringare:', isCaller ? 'Ja' : 'Nej'),
            _infoRow('📥 Remote SDP satt:', remoteDescriptionSet ? '✅ Ja' : '❌ Nej'),
            _infoRow('❄️ ICE skickade:', '$iceSent st'),
            _infoRow('❄️ ICE mottagna:', '$iceReceived st'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
