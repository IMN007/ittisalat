import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignalingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _iceSub;

  String generateCallId(String a, String b) {
    return a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
  }

  Future<void> sendOffer(String callId, RTCSessionDescription offer) async {
    try {
      await _db.collection('calls').doc(callId).set({
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
      });
    } catch (e) {
      print('🚫 sendOffer: $e');
    }
  }

  Future<void> sendAnswer(String callId, RTCSessionDescription answer) async {
    try {
      await _db.collection('calls').doc(callId).update({
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
      });
    } catch (e) {
      print('🚫 sendAnswer: $e');
    }
  }

  void listenForOffer(String callId, Function(RTCSessionDescription offer) onOfferReceived) {
    _offerSub = _db.collection('calls').doc(callId).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['offer'] is Map<String, dynamic>) {
        final offerMap = data['offer'] as Map<String, dynamic>;
        final sdp = offerMap['sdp'];
        final type = offerMap['type'];
        if (sdp != null && type != null) {
          final offer = RTCSessionDescription(sdp, type);
          onOfferReceived(offer);
        }
      }
    });
  }

  void listenForAnswer(String callId, Function(RTCSessionDescription answer) onAnswerReceived) {
    _answerSub = _db.collection('calls').doc(callId).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['answer'] is Map<String, dynamic>) {
        final answerMap = data['answer'] as Map<String, dynamic>;
        final sdp = answerMap['sdp'];
        final type = answerMap['type'];
        if (sdp != null && type != null) {
          final answer = RTCSessionDescription(sdp, type);
          onAnswerReceived(answer);
        }
      }
    });
  }

  Future<void> addIceCandidate(String callId, RTCIceCandidate candidate) async {
    try {
      await _db.collection('calls').doc(callId).collection('candidates').add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    } catch (e) {
      print('🚫 addIceCandidate: $e');
    }
  }

  void listenForIceCandidates(String callId, Function(RTCIceCandidate candidate) onCandidate) {
    _iceSub = _db.collection('calls').doc(callId).collection('candidates').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['candidate'] != null) {
          final candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );
          onCandidate(candidate);
        }
      }
    });
  }

  void stopListening() {
    _offerSub?.cancel();
    _answerSub?.cancel();
    _iceSub?.cancel();
  }

  Future<void> endCall(String callId) async {
    try {
      final candidates = await _db.collection('calls').doc(callId).collection('candidates').get();
      for (var doc in candidates.docs) {
        await doc.reference.delete();
      }
      await _db.collection('calls').doc(callId).delete();
    } catch (e) {
      print('🚫 endCall: $e');
    }
  }
}
