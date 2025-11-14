import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveRate(String pair, double rate) async {
    await _db.collection('rates').add({
      'pair': pair,
      'rate': rate,
      'timestamp': Timestamp.now(),
    });
  }
}
