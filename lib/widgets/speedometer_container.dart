import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'speedometer.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart';

class SpeedometerContainer extends StatefulWidget {
  @override
  _SpeedometerContainerState createState() => _SpeedometerContainerState();
}

class _SpeedometerContainerState extends State<SpeedometerContainer> {
  double velocity = 0;
  double highestVelocity = 0.0;
  double newVelocity = 0.0;

  TextToSpeech tts = TextToSpeech();

  String text = '';
  double volume = 1; // Range: 0-1
  double rate = 1.0; // Range: 0-2
  double pitch = 1.0;

  void speak() {
    tts.setVolume(volume);
    tts.setRate(rate);
    tts.setPitch(pitch);
    tts.speak(text);
  }

  @override
  void initState() {
    // userAccelerometerEvents.listen((UserAccelerometerEvent event) {
    //   _onAccelerate(event);
    // });

    _determinePosition(); //just for authorisations

    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      //distanceFilter: 0,
    )).listen((Position position) {
      _onAccelerate(position);
    });
    super.initState();
  }

  // velocityCal(UserAccelerometerEvent event) {
  //   double velocity =
  //       sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

  //   return velocity;
  // }

  // void _onAccelerate(UserAccelerometerEvent event) {
  //   double newVelocity =
  //       sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

  //   if (newVelocity > 10) {
  //     text = ('slow down you are going beyond the speed limit');
  //     speak();
  //   }

  //   if ((newVelocity - velocity).abs() < 1) {
  //     return;
  //   }

  //}
  Future<Position> _determinePosition() async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // not enabled
      return Future.error('Location services are disabled.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
  }

  void _onAccelerate(Position position) {
    setState(() {
      velocity = position.speed;
      velocity = newVelocity;

      if (velocity > highestVelocity) {
        highestVelocity = velocity;
      }
    });
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      print("ERROR" + error.toString());

      getUserCurrentLocation().then((value) {
        print(value.latitude.toString() + value.longitude.toString());
      });
    });
    return await Geolocator.getCurrentPosition();
  }

  loc.LocationData? currentLocation;
  void getCurrentLocation() async {
    loc.Location location = loc.Location();
    location.getLocation().then(
      (location) {
        currentLocation = location;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Container(
              padding: EdgeInsets.only(bottom: 64),
              alignment: Alignment.bottomCenter,
              child: Text(
                'Highest speed:\n${highestVelocity.toStringAsFixed(2)} km/h',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              )),
          Center(
              child: Speedometer(
            speed: velocity,
            speedRecord: highestVelocity,
          ))
        ]));
  }
}
