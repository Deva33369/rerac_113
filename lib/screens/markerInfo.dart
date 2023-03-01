// ignore_for_file: file_names, depend_on_referenced_packages

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geofence_service/geofence_service.dart';
import 'package:rerac_113/locationInfo/blk23.dart';
import 'package:rerac_113/locationInfo/blk51.dart';
import 'package:rerac_113/locationInfo/blk72.dart';
import 'package:rerac_113/locationInfo/blk73.dart';
import 'package:rerac_113/locationInfo/blk8.dart';
import 'package:rerac_113/locationInfo/sit.dart';
import 'package:rerac_113/widgets/globals.dart';

class MarkerInfo extends StatefulWidget {
  const MarkerInfo({super.key});

  @override
  State<MarkerInfo> createState() => MarkerInfoState();
}

class MarkerInfoState extends State<MarkerInfo> {
  Map riskData = {};
  List<dynamic> waypointData = [];
  String googleApikey = "AIzaSyCsqrq6bn25yMgMQILghZZ3bVcb29V5ubA";
  GoogleMapController? mapController;
  //contrller for Google map
  CameraPosition? cameraPosition;
  LatLng startLocation = const LatLng(1.33206, 103.77436);
  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> markers = {};
  final Set<Circle> _circles = {};

  _getGeofence() {
    _getWaypoint();
    List<Geofence> geofenceList = [];

    for (int i = 0; i < waypointData.length; i++) {
      String id = waypointData[i]["Name"];
      double latitude = waypointData[i]["Latitude"].toDouble();
      double longitude = waypointData[i]["Longitude"].toDouble();
      geofenceList.add(
          Geofence(id: id, latitude: latitude, longitude: longitude, radius: [
        GeofenceRadius(id: 'radius_50m', length: 200),
        GeofenceRadius(id: 'radius_150m', length: 200),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ]));
    }

    return geofenceList;
  }

  _getWaypoint() async {
    final queryParameters = {'request': 'ALL', 'database': 'waypoints'};
    final url = Uri.http(_localhost(), '/get', queryParameters);
    Response response = await get(url);
    if (mounted) {
      setState(() {
        waypointData = jsonDecode(response.body);
      });
    }
  }

  _getRisk() async {
    final queryParameters = {'request': 'ALL', 'database': 'risks'};
    final url = Uri.http(_localhost(), '/get', queryParameters);
    Response response = await get(url);
    if (mounted) {
      setState(() {
        final risks = jsonDecode(response.body).last;
        risks.removeWhere((key, value) => key == "Date");
        risks.removeWhere((key, value) => key == "Time");
        riskData = risks;
      });
    }
  }

  String _localhost() {
    if (Platform.isAndroid) {
      return IPaddress;
    } else {
      return '127.0.0.1:3000';
    }
  }

  @override
  Widget build(BuildContext context) {
    _getGeofence();
    _getRisk();
    rebuildAllChildren(context);

    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          //Map widget from google_maps_flutter package
          zoomControlsEnabled: true,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          zoomGesturesEnabled: true,
          myLocationEnabled: true, //enable Zoom in, out on map
          initialCameraPosition: CameraPosition(
            //innital position in map
            target: startLocation, //initial position
            zoom: 18.0, //initial zoom level
          ),
          mapType: MapType.normal,
          markers: getmarkers(),
          circles: _circles, //map type
          onMapCreated: (controller) {
            _controller.complete(controller);
            //method called when map is created
            setState(() {
              mapController = controller;
              _getRisk();
            });
          },
        ),
        //search autoconplete input

        //alignment: const Alignment(5, 50),
      ]),
    );
  }

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  addMarkers(img, location, id) async {
    BitmapDescriptor markerbitmap = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      img,
    );

    const Map waypointFunction = {
      "Blk 8": Blk8(),
      "Blk 23": Blk23(),
      "Blk 72": Blk72(),
      "Blk 73": Blk73(),
      "Blk 51": Blk51(),
      "SIT": SIT()
    };

    markers.add(Marker(
      //add start location marker
      markerId: MarkerId(id.toString()),
      position: location, //position of marker
      onTap: () {
        for (int i = 0; i < waypointData.length; i++) {
          if (id == waypointData[i]["Name"]) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => waypointFunction[id]));
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    target: LatLng(waypointData[i]["Latitude"],
                        waypointData[i]["Longitude"]),
                    zoom: 17)));
          }
        }
      },
      icon: markerbitmap, //Icon for Marker
    ));
  }

  Set<Marker> getmarkers() {
    _getRisk();
    _getWaypoint();
    Map risk = riskData;

    //markers to place on map
    setState(() {
      for (int i = 0; i < waypointData.length; i++) {
        risk.forEach((key, value) {
          if (key == _getGeofence()[i].id) {
            String assets = 'assets/greenSmile.png';
            Color fillColor = Colors.greenAccent.withOpacity(0.5);
            Color strokeColor = Colors.greenAccent;
            if (value >= 1 && value <= 3) {
              assets = 'assets/greenSmile.png';
              fillColor = Colors.greenAccent.withOpacity(0.5);
              strokeColor = Colors.greenAccent;
            } else if (value >= 4 && value <= 7) {
              assets = 'assets/orangeSmile.png';
              fillColor = Colors.orangeAccent.withOpacity(0.5);
              strokeColor = Colors.orangeAccent;
            } else if (value >= 8 && value <= 10) {
              assets = 'assets/redSmile.png';
              fillColor = Colors.redAccent.withOpacity(0.5);
              strokeColor = Colors.redAccent;
            }

            addMarkers(
                assets,
                LatLng(
                    waypointData[i]["Latitude"], waypointData[i]["Longitude"]),
                key);

            _circles.add(Circle(
                circleId: CircleId(_getGeofence()[i].id),
                center: LatLng(
                    waypointData[i]["Latitude"], waypointData[i]["Longitude"]),
                radius: 25,
                fillColor: fillColor,
                strokeWidth: 3,
                strokeColor: strokeColor));
          }
        });
      }
    });

    return markers;
  }
}
