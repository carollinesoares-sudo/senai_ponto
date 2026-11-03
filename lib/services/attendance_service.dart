import 'package:cloud_firestore/cloud_firestore.dart';

import 'location_service.dart';

class AttendanceService {
  AttendanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentRecords(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  Future<void> createRecord({
    required String userId,
    required String email,
    required AttendanceLocation location,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .add({
      'userId': userId,
      'email': email,
      'timestamp': FieldValue.serverTimestamp(),
      'latitude': location.latitude,
      'longitude': location.longitude,
      'distanceMeters': location.distanceMeters,
      'withinAllowedRadius': location.isWithinWorkplace,
    });
  }
}
