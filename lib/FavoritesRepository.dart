import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hello_me/AuthRepository.dart';

class FavoritesRepository with ChangeNotifier {
  Set<WordPair> _currentSet = Set();
  Set<WordPair> get currentSet => _currentSet;
  User? _user;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void updateFavorites(AuthRepository auth) async {
    if (auth.status!= Status.Authenticating){
      if (auth.user == null) {
        _currentSet.clear();
        _user = null;
        notifyListeners();
      } else {
        _user = auth.user;
        final snapshot=await _firestore.collection('users').doc(_user!.uid).get();
        if (snapshot.exists){
          await _firestore.collection('users').doc(_user!.uid).get().then((value) => value.data())
              .then((userVal) {
            Set<WordPair> cloudSet = Set<WordPair>.from(userVal!['suggestions']
                .map((element) => WordPair(element['first'], element['second'])));
            _currentSet.forEach((element) {addSingleFavorite(element);});
            _currentSet.addAll(cloudSet);
        });
        }else{
          List newList = [];
          await _firestore.collection('users').doc(_user!.uid).set({'suggestions':newList});
          _currentSet.forEach((element) {addSingleFavorite(element);});
        }
      }
    }


    //TODO: merge lists from firebase
    notifyListeners();
  }

  void addSingleFavorite(WordPair pair) async{
    _currentSet.add(pair);
    notifyListeners();
    String first = pair.first;
    String second = pair.second;
    Map temp = new Map();
    temp['first']=first;
    temp['second']=second;
    await _firestore
        .collection('users')
        .doc(_user!.uid).update({'suggestions': FieldValue.arrayUnion([temp])});

  }

  void deleteSingleFavorite(WordPair pair) async {
    _currentSet.remove(pair);
    notifyListeners();
    String first = pair.first;
    String second = pair.second;
    Map temp = new Map();
    temp['first']=first;
    temp['second']=second;
    await _firestore
        .collection('users')
        .doc(_user!.uid).update({'suggestions': FieldValue.arrayRemove([temp])});
  }


}
