import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class Accelero extends StatefulWidget {
  @override
  _AcceleroState createState() => _AcceleroState();
}

class _AcceleroState extends State<Accelero> {
  late double x, y, z;
  late double speed;

  @override
  void initState() {
    // TODO: implement initState
    CalculateSpeed();
    super.initState();
//get the sensor data and set then to the data types
  }

  CalculateSpeed() {
    x = 0;
    y = 0;
    z = 0;
    speed = 0;
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        x = event.x;
        y = event.y;
        z = event.z;
        speed = sqrt(x * x + y * y + z * z);
      });
    });

    return speed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Flutter Sensor Library"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Speed" + speed.toString(),
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ));
  }
}
