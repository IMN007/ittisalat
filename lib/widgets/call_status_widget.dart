import 'package:flutter/material.dart';

class CallStatusWidget extends StatelessWidget {
  final bool offerReceived;
  final bool answerSent;
  final bool iceConnected;
  final bool onTrackReceived;

  const CallStatusWidget({
    required this.offerReceived,
    required this.answerSent,
    required this.iceConnected,
    required this.onTrackReceived,
    super.key,
  });

  Widget _statusRow(String label, bool status) {
    return Row(
      children: [
        Icon(
          status ? Icons.check_circle : Icons.hourglass_empty,
          color: status ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusRow('📥 Offer mottagen', offerReceived),
        _statusRow('📤 Answer skickad', answerSent),
        _statusRow('🧭 ICE connected', iceConnected),
        _statusRow('🎙️ Ljudström aktiv (onTrack)', onTrackReceived),
      ],
    );
  }
}
