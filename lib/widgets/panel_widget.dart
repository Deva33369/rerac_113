import 'package:flutter/material.dart';

class PanelWidget extends StatelessWidget {
  final ScrollController controller;
  const PanelWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          SizedBox(height: 36),
          buildAboutText(),
          SizedBox(height: 24),
        ],
      );
  Widget buildAboutText() => Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text("hello"),
        ],
      ));
}
