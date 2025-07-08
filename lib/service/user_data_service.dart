import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sona/model/audio_model.dart';

class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   final String uid;

   UserDataService(this.uid);


  Future<void> addToFavorites(AudioModel audio) async {
    await _firestore.collection('users/$uid/favorites').doc(audio.id).set(audio.toMap());
  }

  Future<void> removeFromFavorites(String audioId) async {
    await _firestore.collection('users/$uid/favorites').doc(audioId).delete();
  }

  Future<List<AudioModel>> getFavorites() async {
    final snapshot = await _firestore.collection('users/$uid/favorites').get();
    return snapshot.docs.map((doc) => AudioModel.fromMap(doc.data())).toList();
  }

  Future<void> addToHistory(AudioModel audio) async {
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('users/$uid/history').add({
      ...audio.toMap(),
      'playedAt': now,
    });
  }
}
