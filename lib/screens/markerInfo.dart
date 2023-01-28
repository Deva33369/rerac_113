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

class markerInfo extends StatefulWidget {
  const markerInfo({super.key});

  @override
  State<markerInfo> createState() => _markerInfoState();
}

class _markerInfoState extends State<markerInfo> {
  String googleApikey = "AIzaSyCsqrq6bn25yMgMQILghZZ3bVcb29V5ubA";
  GoogleMapController? mapController;
  //contrller for Google map
  CameraPosition? cameraPosition;
  LatLng zoomLocation = LatLng(1.33206, 103.77436);
  Completer<GoogleMapController> _controller = Completer();
  final _geofenceStreamController = StreamController<Geofence>.broadcast();

  final Set<Marker> markers = new Set();
  final Set<Circle> _circles = new Set();

  final _geofenceList = <Geofence>[
    // Geofence(
    //   id: 'clementi_mall',
    //   latitude: 37.4220936, coordinates for googleplex(default location of the emulator)
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

  @override
  Widget build(BuildContext context) {
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
            target: zoomLocation, //initial position
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
            });
          },
        ),
        //search autoconplete input

        //alignment: const Alignment(5, 50),
      ]),
    );
  }

  addMarkers(img, location, id) async {
    BitmapDescriptor markerbitmap = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      img,
    );

    markers.add(Marker(
      //add start location marker
      markerId: MarkerId(id.toString()),
      position: location, //position of marker
      onTap: () {
        for (int i = 0; i < 6; i++) {
          if (_geofenceList[i].id == 'blk8') {
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    target: LatLng(1.334792177762611, 103.77629441346048),
                    zoom: 17)
                //17 is new zoom level
                ));
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => blk8()));
          } else if (_geofenceList[i].id == 'blk23') {
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    target: LatLng(1.3339717453574258, 103.77531565381817),
                    zoom: 17)
                //17 is new zoom level
                ));
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => blk23()));
          } else if (_geofenceList[i].id == 'blk51') {
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    target: LatLng(37.4220936, -122.083922), zoom: 17)
                //17 is new zoom level
                ));
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => blk51()));
          } else if (_geofenceList[i].id == 'blk72') {
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    target: LatLng(1.3318895388375338, 103.77571465588211),
                    zoom: 17)
                //17 is new zoom level
                ));
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => blk72()));
          } else if (_geofenceList[i].id == 'blk73') {
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    target: LatLng(1.3320323222018304, 103.77649335992052),
                    zoom: 17)
                //17 is new zoom level
                ));
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => blk73()));
          } else if (_geofenceList[i].id == 'sit') {
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    target: LatLng(1.3342380695589044, 103.7744542762125),
                    zoom: 17)
                //17 is new zoom level
                ));
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => sit()));
          }
        }
      },
      icon: markerbitmap, //Icon for Marker
    ));
  }

  Set<Marker> getmarkers() {
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
          addMarkers(
              'assets/greenCamera.png',
              LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude),
              _geofenceList[i].id.toString());

          _circles.add(Circle(
              circleId: CircleId(_geofenceList[i].id.toString()),
              center:
                  LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude),
              radius: 25,
              fillColor: Colors.greenAccent.withOpacity(0.5),
              strokeWidth: 3,
              strokeColor: Colors.greenAccent));
        } else if (risknum[_geofenceList[i].id.toString()] == '2') {
          addMarkers(
              'assets/orangeCamera.png',
              LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude),
              _geofenceList[i].id.toString());

          _circles.add(Circle(
              circleId: CircleId(_geofenceList[i].id.toString()),
              center:
                  LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude),
              radius: 25,
              fillColor: Colors.orangeAccent.withOpacity(0.5),
              strokeWidth: 3,
              strokeColor: Colors.orangeAccent));
        } else if (risknum[_geofenceList[i].id.toString()] == '3') {
          addMarkers(
              'assets/redCamera.png',
              LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude),
              _geofenceList[i].id.toString());

          _circles.add(Circle(
              circleId: CircleId(_geofenceList[i].id.toString()),
              center:
                  LatLng(_geofenceList[i].latitude, _geofenceList[i].longitude),
              radius: 25,
              fillColor: Colors.redAccent.withOpacity(0.5),
              strokeWidth: 3,
              strokeColor: Colors.redAccent));
        }
      }

      //add more markers here
    });

    return markers;
  }
}
