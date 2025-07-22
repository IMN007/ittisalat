import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../widgets/call_status_widget.dart';

// Importera audioplayers om du vill återaktivera ringsignalen senare, annars kan du ta bort den.
// import 'package:audioplayers/audioplayers.dart';

class CallPage extends StatefulWidget {
  final String myIdentity;
  final String peerIdentity;
  final bool isCaller;

  const CallPage({
    required this.myIdentity,
    required this.peerIdentity,
    required this.isCaller,
    super.key,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final firebase = FirebaseService();
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  String statusMessage = '🔄 Initierar samtal...';

  bool offerReceived = false;
  bool answerSent = false;
  bool iceConnected = false;
  bool onTrackReceived = false;
  bool callEndedRemotely = false;

  String get callId => widget.myIdentity.compareTo(widget.peerIdentity) < 0
      ? '${widget.myIdentity}|${widget.peerIdentity}'
      : '${widget.peerIdentity}|${widget.myIdentity}';

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
    _startCall();
    _listenForRemoteEnd();
  }

  void _listenForRemoteEnd() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists && mounted && _pc != null) {
        setState(() {
          callEndedRemotely = true;
          statusMessage = '📴 Samtalet har avslutats av motparten';
        });
        _cleanup();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  Future<void> _startCall() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    try {
      print('📞 Startar samtal med callId = $callId');

      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true});
      _pc = await createPeerConnection(config);

      _localStream!.getTracks().forEach((track) {
        _pc!.addTrack(track, _localStream!);
      });

      _pc!.onTrack = (event) {
        print('🚀 onTrack triggered! Kind: ${event.track.kind}, Stream ID: ${event.streams.isNotEmpty ? event.streams[0].id : 'N/A'}');
        if (event.streams.isNotEmpty && event.track.kind == 'audio') {
          if (_remoteStream == null || _remoteStream!.id != event.streams[0].id) {
            setState(() {
              _remoteStream = event.streams[0];
              _remoteRenderer.srcObject = _remoteStream;
              onTrackReceived = true;
              statusMessage = '✅ Ljudström mottagen! Samtal upprättat.';
            });
            print('✅ Ljudström mottagen och tilldelad till remoteRenderer!');
          }
        }
      };

      _pc!.onAddStream = (stream) {
        print('🚀 onAddStream triggered! Stream ID: ${stream.id}');
        if (stream.getAudioTracks().isNotEmpty) {
          if (_remoteStream == null || _remoteStream!.id != stream.id) {
            setState(() {
              _remoteStream = stream;
              _remoteRenderer.srcObject = _remoteStream;
              onTrackReceived = true;
              statusMessage = '✅ Ljudström mottagen (onAddStream)! Samtal upprättat.';
            });
            print('✅ Ljudström mottagen och tilldelad till remoteRenderer via onAddStream!');
          }
        }
      };

      _pc!.onIceConnectionState = (state) {
        print('ICE connection state: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          setState(() => iceConnected = true);
          if (!onTrackReceived) {
            setState(() => statusMessage = '🌐 ICE-anslutning upprättad.');
          }
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
                   state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          setState(() => statusMessage = '⚠️ ICE-koppling tappad eller misslyckad.');
          _cleanup();
          if (mounted && !callEndedRemotely) {
            Navigator.pop(context);
          }
        }
      };

      // ** ÄNDRING HÄR: Skickar kandidater till korrekt sub-kollektion **
      _pc!.onIceCandidate = (candidate) {
        if (candidate != null) {
          // Skicka kandidater till motpartens "mottagnings-kollektion"
          final String candidateCollectionType = widget.isCaller ? 'callerCandidates' : 'calleeCandidates';
          firebase.addCandidate(callId, candidateCollectionType, { // Ny parameter!
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
          print('👍 Skickar ICE-kandidat till "$candidateCollectionType".');
        }
      };

      // ** ÄNDRING HÄR: Lyssnar på kandidater från korrekt sub-kollektion **
      FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .collection(widget.isCaller ? 'calleeCandidates' : 'callerCandidates') // Lyssna på motpartens kandidater
          .snapshots()
          .listen((snapshot) {
        for (var doc in snapshot.docChanges) {
          if (doc.type == DocumentChangeType.added) {
            final data = doc.doc.data();
            if (data != null) {
              final candidate = RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              );
              _pc?.addCandidate(candidate);
              print('👍 Lägger till ICE-kandidat från motpart (från ${widget.isCaller ? 'calleeCandidates' : 'callerCandidates'}).');
            }
          }
        }
      });

      if (widget.isCaller) {
        setState(() => statusMessage = '⏳ Skickar samtalserbjudande...');
        final offer = await _pc!.createOffer();
        await _pc!.setLocalDescription(offer);

        await firebase.sendOffer(
          callId: callId,
          sdp: offer.sdp ?? '',
          type: offer.type ?? '',
          from: widget.myIdentity,
          to: widget.peerIdentity,
        );
        print('📤 Erbjudande skickat till Firebase.');

        FirebaseFirestore.instance
            .collection('calls')
            .doc(callId)
            .snapshots()
            .listen((snapshot) {
              final data = snapshot.data();
              final answer = data?['answer'];
              final sdp = answer?['sdp'];
              final type = answer?['type'];
              if (_pc != null && sdp != null && type != null && !answerSent) {
                _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
                setState(() {
                  answerSent = true;
                  statusMessage = '✅ Svar mottaget från motpart.';
                });
                print('✅ Svar mottaget från Firebase och satt som remote description.');
              }
            });
      } else {
        setState(() => statusMessage = '⏳ Väntar på samtalserbjudande...');
        FirebaseFirestore.instance
            .collection('calls')
            .doc(callId)
            .snapshots()
            .listen((snapshot) async {
              final data = snapshot.data();
              final offer = data?['offer'];
              final sdp = offer?['sdp'];
              final type = offer?['type'];

              if (offer != null && sdp != null && type != null && !offerReceived) {
                setState(() {
                  offerReceived = true;
                  statusMessage = '✅ Samtalserbjudande mottaget! Svarar...';
                });
                print('✅ Erbjudande mottaget från Firebase.');

                if (_pc != null) {
                  await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
                  final answer = await _pc!.createAnswer();
                  await _pc!.setLocalDescription(answer);
                  await firebase.sendAnswer(callId, {
                    'sdp': answer.sdp ?? '',
                    'type': answer.type ?? '',
                  });
                  setState(() {
                    answerSent = true;
                    statusMessage = '✅ Svar skickat till uppringare.';
                  });
                  print('↩️ Svar skickat till Firebase.');
                }
              }
            });
      }
    } catch (e) {
      print('Error during call setup: $e');
      setState(() => statusMessage = '⚠️ Fel vid samtal: $e');
      _cleanup();
      if (mounted) Navigator.pop(context);
    }
  }

  void _cleanup() {
    print('🧹 Rengör samtalsresurser...');
    if (_pc == null) return;

    _localStream?.getTracks().forEach((track) => track.dispose());
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.getTracks().forEach((track) => track.dispose());
    _remoteStream?.dispose();
    _remoteStream = null;

    _pc?.close();
    _pc?.dispose();
    _pc = null;

    if (_remoteRenderer.srcObject != null) {
      _remoteRenderer.srcObject = null;
      _remoteRenderer.dispose();
    }
    print('✅ Samtalsresurser rengjorda.');
  }

  @override
  void dispose() {
    if (!callEndedRemotely) {
       firebase.endCall(callId);
    }
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Samtal med ${widget.peerIdentity}')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: (_remoteRenderer.srcObject == null || _remoteStream == null || _remoteStream!.getAudioTracks().isEmpty)
                  ? Text(
                      onTrackReceived
                          ? 'Ingen videoström (detta är ett ljudsamtal)'
                          : statusMessage,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    )
                  : RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              statusMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: CallStatusWidget(
              offerReceived: offerReceived,
              answerSent: answerSent,
              iceConnected: iceConnected,
              onTrackReceived: onTrackReceived,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ElevatedButton(
              onPressed: () {
                _cleanup();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Avsluta samtal', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}