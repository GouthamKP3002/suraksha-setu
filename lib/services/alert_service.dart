import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';

// ─────────────────────────────────────────────
//  PASTE YOUR EMAILJS KEYS HERE
// ─────────────────────────────────────────────
const String _emailjsServiceId  = 'service_ht9q5xl';
const String _emailjsTemplateId = 'template_2bdqfk5';
const String _emailjsPublicKey  = 'esR40sNlRRtEthtTf';
// ─────────────────────────────────────────────

class AlertService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  Future<String?> triggerAlert() async {
    final uid = _auth.currentUid;
    if (uid == null) return null;

    // 1. GPS
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }

    final lat      = position?.latitude;
    final lng      = position?.longitude;
    final mapsLink = (lat != null && lng != null)
        ? 'https://maps.google.com/?q=$lat,$lng'
        : 'Location unavailable';

    // 2. Sender profile
    final userDoc  = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data()!;
    final senderName  = userData['name']  as String? ?? 'Someone';
    final senderPhone = userData['phone'] as String? ?? '';

    // 3. Load safe circle — plain contacts, no app account needed
    final circleSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('safe_circle')
        .get();

    final circleMembers = circleSnap.docs.map((d) => d.data()).toList();

    // 4. Save alert to Firestore
    final alertRef = await _db.collection('alerts').add({
      'senderUid':   uid,
      'senderName':  senderName,
      'senderPhone': senderPhone,
      'latitude':    lat,
      'longitude':   lng,
      'mapsLink':    mapsLink,
      'status':      'active',
      'timestamp':   FieldValue.serverTimestamp(),
      'resolvedAt':  null,
      // store circle snapshot so history is readable later
      'circleSnapshot': circleMembers.map((m) => {
        'name':  m['name'],
        'phone': m['phone'],
        'email': m['email'] ?? '',
      }).toList(),
    });

    // 5. Email every contact that has an email address
    for (final member in circleMembers) {
      final email = (member['email'] as String? ?? '').trim();
      final name  = member['name']  as String? ?? 'Friend';
      if (email.isNotEmpty) {
        await _sendEmail(
          toEmail:     email,
          toName:      name,
          senderName:  senderName,
          senderPhone: senderPhone,
          mapsLink:    mapsLink,
        );
      }
    }

    // 6. SMS all contacts that have a phone number
    final phones = circleMembers
        .map((m) => (m['phone'] as String? ?? '').trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (phones.isNotEmpty) {
      await _sendSmsViaIntent(
        phones:      phones,
        senderName:  senderName,
        senderPhone: senderPhone,
        mapsLink:    mapsLink,
      );
    }

    return alertRef.id;
  }

  // ── EmailJS ──────────────────────────────────────────────────────
  Future<void> _sendEmail({
    required String toEmail,
    required String toName,
    required String senderName,
    required String senderPhone,
    required String mapsLink,
  }) async {
    try {
      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':  _emailjsServiceId,
          'template_id': _emailjsTemplateId,
          'user_id':     _emailjsPublicKey,
          'template_params': {
            'to_email':     toEmail,
            'to_name':      toName,
            'sender_name':  senderName,
            'sender_phone': senderPhone,
            'maps_link':    mapsLink,
            'time':         DateTime.now().toString(),
          },
        }),
      );
    } catch (_) {
      // silent — SMS still fires
    }
  }

  // ── SMS via native sms: URI — zero packages needed ───────────────
  Future<void> _sendSmsViaIntent({
    required List<String> phones,
    required String senderName,
    required String senderPhone,
    required String mapsLink,
  }) async {
    final message = Uri.encodeComponent(
      'SURAKSHA-SETU ALERT\n'
      '$senderName needs help!\n'
      'Call: $senderPhone\n'
      'Location: $mapsLink',
    );
    final recipients = phones.join(';');
    final uri = Uri.parse('sms:$recipients?body=$message');
    try {
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (_) {}
  }

  // ── Resolve ──────────────────────────────────────────────────────
  Future<void> resolveAlert(String alertId) async {
    await _db.collection('alerts').doc(alertId).update({
      'status':     'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Streams ──────────────────────────────────────────────────────
  Stream<QuerySnapshot> alertHistory() {
    final uid = _auth.currentUid;
    return _db
        .collection('alerts')
        .where('senderUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  // Incoming alerts no longer needed (circle members don't need app accounts)
  // Kept for compatibility
  Stream<QuerySnapshot> incomingAlerts() {
    final uid = _auth.currentUid;
    return _db
        .collection('alerts')
        .where('senderUid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}