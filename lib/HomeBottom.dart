import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import 'package:hello_me/AuthRepository.dart';


class HomeBottom extends StatelessWidget {
  firebase_storage.FirebaseStorage _storage;
  String _email;
  HomeBottom(this._email, this._storage);
  @override
  Widget build(BuildContext context) {


    return Consumer<AuthRepository>(
      builder: (context, auth, _) => Container(
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: auth.avatarURL!.isEmpty==false? DecorationImage(
                      image: NetworkImage(auth.avatarURL!),
                      fit: BoxFit.fill
                  ):null,
                ),
              ),],
            ),
            Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:[Text(_email),
              ElevatedButton(onPressed:(){changeAvatar(auth);} ,
                  style: ElevatedButton.styleFrom(primary: Colors.teal[700]),
                  child: Text("Change Avatar"))]


            )
          ],
        ),
      ),
    );
  }

  Future<void> changeAvatar (AuthRepository auth) async {

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if(result != null) {

      File file = File(result.files.single.path!);
      var temp = await _storage.ref('${auth.user!.uid}').putFile(file);
      var url = await temp.ref.getDownloadURL();      //.snapshot.ref.getDownloadURL();
      auth.changeAvatarURL(url);
    } else {
      // User canceled the picker
    }
  }
}