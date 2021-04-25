import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class GrabbingWidget extends StatelessWidget {
  String _email;
  GrabbingWidget(this._email);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey[200],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          Text("Welcome back, $_email",
          ),

          Icon(Icons.keyboard_arrow_up),
        ],
      ),
    );
  }
}