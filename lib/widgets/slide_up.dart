import 'package:flutter/material.dart';
import 'package:rerac_113/screens/home.dart';
import 'package:rerac_113/screens/markerInfo.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as web;
import 'dart:async';
import 'package:geofence_service/geofence_service.dart';

class SlidePanel extends StatefulWidget {
  const SlidePanel({super.key});

  @override
  State<SlidePanel> createState() => _SlidePanelState();
}

class _SlidePanelState extends State<SlidePanel> {
  BorderRadiusGeometry radius = const BorderRadius.only(
    topLeft: Radius.circular(24.0),
    topRight: Radius.circular(24.0),
  );
  final _geofenceStreamController = StreamController<Geofence>.broadcast();

  final Set<Marker> markers = new Set();
  final Set<Circle> _circles = new Set();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(
                context, MaterialPageRoute(builder: (context) => Home()));
          },
          icon: CircleAvatar(
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SlidingUpPanel(
        panel: const Center(
          child: Text("this is slide up shit"),
        ),
        collapsed: Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: radius,
          ),
          child: const Center(
            child: Text(
              "This is the collasped widget",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        body: const markerInfo(),
        borderRadius: radius,
      ),
    );
  }

  final _geofenceList = <Geofence>[
    // Geofence(
    //   id: 'clementi_mall',
    //   latitude: 37.4220936,
    //   longitude: -122.083922,
    //   radius: [
    //     GeofenceRadius(id: 'radius_100m', length: 100),
    //     GeofenceRadius(id: 'radius_25m', length: 25),
    //     GeofenceRadius(id: 'radius_250m', length: 250),
    //     GeofenceRadius(id: 'radius_200m', length: 200),
    //   ],
    // ),
    Geofence(
      id: 'blk51',
      latitude: 1.34683,
      longitude: 103.69919,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
    Geofence(
      id: 'blk72',
      latitude: 1.3318895388375338,
      longitude: 103.77571465588211,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
    Geofence(
      id: 'blk73',
      latitude: 1.3320323222018304,
      longitude: 103.77649335992052,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
    Geofence(
      id: 'blk23',
      latitude: 1.3339717453574258,
      longitude: 103.77531565381817,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
    Geofence(
      id: 'blk8',
      latitude: 1.334792177762611,
      longitude: 103.77629441346048,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
    Geofence(
      id: 'sit',
      latitude: 1.3342380695589044,
      longitude: 103.7744542762125,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ],
    ),
  ];

  getmarkers() {
    var risknum = {
      _geofenceList[0].id.toString(): '3',
      _geofenceList[1].id.toString(): '2',
      _geofenceList[2].id.toString(): '3',
      _geofenceList[3].id.toString(): '1',
      _geofenceList[4].id.toString(): '2',
      _geofenceList[5].id.toString(): '3',
    };

    //markers to place on map
    setState(() {
      for (int i = 0; i < 6; i++) {
        if (risknum[_geofenceList[i].id.toString()] == '1') {
          String location =
              LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude)
                  .toString();

          String locName = _geofenceList[i].id.toString();
        } else if (risknum[_geofenceList[i].id.toString()] == '2') {
          String location =
              LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude)
                  .toString();

          String locName = _geofenceList[i].id.toString();
        } else if (risknum[_geofenceList[i].id.toString()] == '3') {
          String location =
              LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude)
                  .toString();

          String locName = _geofenceList[i].id.toString();
        }
      }

      //add more markers here
    });
  }
}
