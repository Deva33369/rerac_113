// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:geofence_service/geofence_service.dart';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:rerac_113/map_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:geofence_service/geofence_service.dart' as geo;
import 'package:rerac_113/locationInfo/blk23.dart';
import 'package:rerac_113/locationInfo/blk72.dart';
import 'package:rerac_113/locationInfo/blk73.dart';
import 'package:geolocator/geolocator.dart' as geoloc;
import 'package:rerac_113/locationInfo/blk8.dart';
import 'package:rerac_113/locationInfo/sit.dart';
import 'package:rerac_113/locationInfo/blk51.dart';

class MapScreen extends StatefulWidget {
  final DetailsResult? startPosition;
  final DetailsResult? endPosition;

  const MapScreen({Key? key, this.startPosition, this.endPosition})
      : super(key: key);
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Map riskData = {};
  List<dynamic> waypointData = [];
  late CameraPosition _initialPosition;
  GoogleMapController? mapController;
  final Completer<GoogleMapController> _controller = Completer();
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  double velocity = 0;
  int waypointCounter = 0;

  final Set<Marker> markers = new Set();
  final Set<Circle> _circles = new Set();

  _getWaypoint() async {
    final queryParameters = {'request': 'ALL', 'database': 'waypoints'};
    final url = Uri.http(_localhost(), '/get', queryParameters);
    Response response = await get(url);
    setState(() {
      waypointData = jsonDecode(response.body);
    });
  }

  _getRisk() async {
    final queryParameters = {'request': 'ALL', 'database': 'risks'};
    final url = Uri.http(_localhost(), '/get', queryParameters);
    Response response = await get(url);
    setState(() {
      final risks = jsonDecode(response.body).last;
      riskData = risks;
    });
  }

  String _localhost() {
    if (Platform.isAndroid) {
      return '10.0.2.2:3000';
    } else {
      return '127.0.0.1:3000';
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _determinePosition(); //just for authorisations

    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: geoloc.LocationAccuracy.bestForNavigation,
      //distanceFilter: 0,
    )).listen((Position position) {
      _onAccelerate(position);
    });

    super.initState();
    _initialPosition = CameraPosition(
      target: LatLng(widget.startPosition!.geometry!.location!.lat!,
          widget.startPosition!.geometry!.location!.lng!),
      zoom: 14.4746,
    );
  }

  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  BusStopMarker() async {
    final Uint8List markIcons = await getImages('assets/bus_stop.png', 100);
    // makers added according to index
    markers.add(Marker(
      // given marker id
      markerId: MarkerId("bus stop timings"),
      // given marker icon
      icon: BitmapDescriptor.fromBytes(markIcons),
      // given position
      position: LatLng(1.332452, 103.777685),
      infoWindow: InfoWindow(
        // given title for marker
        title: 'bus timings',
      ),

      onTap: () {},
    ));
  }

  _getGeofence() {
    List<Geofence> geofenceList = [];

    for (int i = 0; i < waypointData.length; i++) {
      String id = waypointData[i]["Name"].replaceAll(" ", "").toLowerCase();
      double latitude = waypointData[i]["Latitude"].toDouble();
      double longitude = waypointData[i]["Longitude"].toDouble();
      geofenceList.add(
          Geofence(id: id, latitude: latitude, longitude: longitude, radius: [
        GeofenceRadius(id: 'radius_25m', length: 25),
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_200m', length: 200),
      ]));
    }
    return geofenceList;
  }
  // final _geofenceList = <geo.Geofence>[
  //   // Geofence(
  //   //   id: 'clementi_mall',
  //   //   latitude: 37.4220936,
  //   //   longitude: -122.083922,
  //   //   radius: [
  //   //     GeofenceRadius(id: 'radius_100m', length: 100),
  //   //     GeofenceRadius(id: 'radius_25m', length: 25),
  //   //     GeofenceRadius(id: 'radius_250m', length: 250),
  //   //     GeofenceRadius(id: 'radius_200m', length: 200),
  //   //   ],
  //   // ),
  //   geo.Geofence(
  //     id: 'blk51',
  //     latitude: 37.4220936,
  //     longitude: -122.083922,
  //     radius: [
  //       geo.GeofenceRadius(id: 'radius_25m', length: 200),
  //       geo.GeofenceRadius(id: 'radius_100m', length: 250),
  //       geo.GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   geo.Geofence(
  //     id: 'blk72',
  //     latitude: 1.3318895388375338,
  //     longitude: 103.77571465588211,
  //     radius: [
  //       geo.GeofenceRadius(id: 'radius_25m', length: 200),
  //       geo.GeofenceRadius(id: 'radius_100m', length: 250),
  //       geo.GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   geo.Geofence(
  //     id: 'blk73',
  //     latitude: 1.3320323222018304,
  //     longitude: 103.77649335992052,
  //     radius: [
  //       geo.GeofenceRadius(id: 'radius_25m', length: 200),
  //       geo.GeofenceRadius(id: 'radius_100m', length: 250),
  //       geo.GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   geo.Geofence(
  //     id: 'blk23',
  //     latitude: 1.3339717453574258,
  //     longitude: 103.77531565381817,
  //     radius: [
  //       geo.GeofenceRadius(id: 'radius_25m', length: 200),
  //       geo.GeofenceRadius(id: 'radius_100m', length: 250),
  //       geo.GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   geo.Geofence(
  //     id: 'blk8',
  //     latitude: 1.334792177762611,
  //     longitude: 103.77629441346048,
  //     radius: [
  //       geo.GeofenceRadius(id: 'radius_25m', length: 200),
  //       geo.GeofenceRadius(id: 'radius_100m', length: 250),
  //       geo.GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   geo.Geofence(
  //     id: 'sit',
  //     latitude: 1.3342380695589044,
  //     longitude: 103.7744542762125,
  //     radius: [
  //       geo.GeofenceRadius(id: 'radius_25m', length: 200),
  //       geo.GeofenceRadius(id: 'radius_100m', length: 250),
  //       geo.GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  // ];

  addMarkers(img, location, id) async {
    BitmapDescriptor markerbitmap = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      img,
    );
    markers.add(Marker(
        markerId: MarkerId('start'),
        position: LatLng(widget.startPosition!.geometry!.location!.lat!,
            widget.startPosition!.geometry!.location!.lng!)));
    markers.add(Marker(
        markerId: MarkerId('end'),
        position: LatLng(widget.endPosition!.geometry!.location!.lat!,
            widget.endPosition!.geometry!.location!.lng!)));

    markers.add(Marker(
      //add start location marker
      markerId: MarkerId(id.toString()),
      position: location, //position of marker
      onTap: () {
        if (id == 'blk8') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk8()));
        } else if (id == 'blk23') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk23()));
        } else if (id == 'blk51') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk51()));
        } else if (id == 'blk72') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk72()));
        } else if (id == 'blk73') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk73()));
        } else if (id == 'sit') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => sit()));
        }
      },
      icon: markerbitmap, //Icon for Marker
    ));
  }

  Set<Marker> _markers() {
    _getRisk();
    var risknum = {
      _getGeofence()[0].id.toString(): riskData["Blk 51"].toString(),
      _getGeofence()[1].id.toString(): riskData["Blk 72"].toString(),
      _getGeofence()[2].id.toString(): riskData["Blk 73"].toString(),
      _getGeofence()[3].id.toString(): riskData["Blk 23"].toString(),
      _getGeofence()[4].id.toString(): riskData["Blk 8"].toString(),
      _getGeofence()[5].id.toString(): riskData["SIT"].toString(),
    };
    //markers to place on map
    setState(() {
      for (int i = 0; i < 6; i++) {
        if (risknum[_getGeofence()[i].id.toString()] == '1') {
          addMarkers(
              'assets/greenCamera.png',
              LatLng(_getGeofence()[i].latitude, _getGeofence()[i].longitude),
              _getGeofence()[i].id.toString());

          _circles.add(Circle(
              circleId: CircleId(_getGeofence()[i].id.toString()),
              center: LatLng(
                  _getGeofence()[i].latitude, _getGeofence()[i].longitude),
              radius: 25,
              fillColor: Colors.greenAccent.withOpacity(0.5),
              strokeWidth: 3,
              strokeColor: Colors.greenAccent));
        } else if (risknum[_getGeofence()[i].id.toString()] == '2') {
          addMarkers(
              'assets/orangeCamera.png',
              LatLng(_getGeofence()[i].latitude, _getGeofence()[i].longitude),
              _getGeofence()[i].id.toString());

          _circles.add(Circle(
              circleId: CircleId(_getGeofence()[i].id.toString()),
              center: LatLng(
                  _getGeofence()[i].latitude, _getGeofence()[i].longitude),
              radius: 25,
              fillColor: Colors.orangeAccent.withOpacity(0.5),
              strokeWidth: 3,
              strokeColor: Colors.orangeAccent));
        } else if (risknum[_getGeofence()[i].id.toString()] == '3') {
          addMarkers(
              'assets/redCamera.png',
              LatLng(_getGeofence()[i].latitude, _getGeofence()[i].longitude),
              _getGeofence()[i].id.toString());

          _circles.add(Circle(
              circleId: CircleId(_getGeofence()[i].id.toString()),
              center: LatLng(
                  _getGeofence()[i].latitude, _getGeofence()[i].longitude),
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

  Future<Position> _determinePosition() async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // not enabled
      return Future.error('Location services are disabled.');
    }

    return await geoloc.Geolocator.getCurrentPosition(
        desiredAccuracy: geoloc.LocationAccuracy.bestForNavigation);
  }

  void _onAccelerate(Position position) {
    setState(() {
      velocity = position.speed;
    });
  }

  loc.LocationData? currentLocation;
  void getCurrentLocation() async {
    loc.Location location = loc.Location();
    location.getLocation().then(
      (location) {
        currentLocation = location;
      },
    );
    GoogleMapController googleMapController = await _controller.future;
    location.onLocationChanged.listen(
      (newLoc) {
        currentLocation = newLoc;
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 13.5,
              target: LatLng(
                newLoc.latitude!,
                newLoc.longitude!,
              ),
            ),
          ),
        );
        setState(() {});
      },
    );
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

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates,
        width: 3);
    polylines[id] = polyline;
    setState(() {});
  }

  double totalDistance = 0;

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyCsqrq6bn25yMgMQILghZZ3bVcb29V5ubA',
        PointLatLng(widget.startPosition!.geometry!.location!.lat!,
            widget.startPosition!.geometry!.location!.lng!),
        PointLatLng(widget.endPosition!.geometry!.location!.lat!,
            widget.endPosition!.geometry!.location!.lng!),
        travelMode: TravelMode.driving);

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
  }

  @override
  Widget build(BuildContext context) {
    // Set<Marker> _markers = {
    //   Marker(
    //       markerId: MarkerId('start'),
    //       position: LatLng(widget.startPosition!.geometry!.location!.lat!,
    //           widget.startPosition!.geometry!.location!.lng!)),
    //   Marker(
    //       markerId: MarkerId('end'),
    //       position: LatLng(widget.endPosition!.geometry!.location!.lat!,
    //           widget.endPosition!.geometry!.location!.lng!))
    // };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
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
      body: Stack(
        children: [
          GoogleMap(
            polylines: Set<Polyline>.of(polylines.values),
            initialCameraPosition: _initialPosition,
            compassEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers(),
            onMapCreated: (controller) {
              _controller.complete(controller);
              setState(() {
                mapController = controller;
              });
              Future.delayed(Duration(milliseconds: 2000), () {
                // controller.animateCamera(CameraUpdate.newLatLngBounds(
                //     MapUtils.boundsFromLatLngList(
                //         _markers.map((loc) => loc.position).toList()),
                //     1));
                _getPolyline();
                controller.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(
                            widget.startPosition!.geometry!.location!.lat!,
                            widget.startPosition!.geometry!.location!.lng!),
                        zoom: 21.0,
                        bearing: 90.0,
                        tilt: 45.0)));
              });
              controller.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: LatLng(
                          widget.startPosition!.geometry!.location!.lat!,
                          widget.startPosition!.geometry!.location!.lng!),
                      zoom: 10.0,
                      bearing: 90.0,
                      tilt: 45.0)));
            },
          ),
          Positioned(
              bottom: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Speed: " + velocity.toStringAsFixed(2) + " KM/h",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ))
        ],
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.only(top: 50, right: 0),
        alignment: Alignment.topRight,
        child: Column(
          //will break to another line on overflow
          //use vertical to show  on vertical axis
          children: <Widget>[
            Container(
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "curr_loc",
                  onPressed: () {
                    getUserCurrentLocation().then((value) async {
                      print(value.latitude.toString() +
                          " " +
                          value.longitude.toString());

                      // specified current users location
                      CameraPosition cameraPosition = new CameraPosition(
                        target: LatLng(value.latitude, value.longitude),
                        zoom: 18,
                      );

                      final GoogleMapController controller =
                          await _controller.future;
                      controller.animateCamera(
                          CameraUpdate.newCameraPosition(cameraPosition));
                      setState(() {});
                    });
                    //   //action code for button 1
                  },
                  child: Icon(Icons.my_location),
                )), //button first

            Container(
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "map",
                  onPressed: () {
                    MapUtils.openMap(
                        widget.endPosition!.geometry!.location!.lat!,
                        widget.endPosition!.geometry!.location!.lng!);
                  },
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.map_outlined),
                )),
          ],
        ),
      ),
    );
  }
}
