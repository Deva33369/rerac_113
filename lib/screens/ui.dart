import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:rerac_113/screens/loginPage.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    getUserCurrentLocation();
    startTime();
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      print("ERROR" + error.toString());
    });
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: initScreen(context),
    );
  }

  startTime() async {
    var duration = new Duration(seconds: 6);
    return new Timer(duration, route);
  }

  route() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => MainPage()));
  }

  initScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: Image.asset("assets/icon.png"),
            ),
            Padding(padding: EdgeInsets.only(top: 20.0)),
            Text(
              "ReRac",
              style: TextStyle(
                  fontSize: 20.0, color: Color.fromARGB(255, 252, 252, 252)),
            ),
            Padding(padding: EdgeInsets.only(top: 20.0)),
            CircularProgressIndicator(
              backgroundColor: Color.fromARGB(255, 0, 0, 0),
              strokeWidth: 1,
            )
          ],
        ),
      ),
    );
  }
}
