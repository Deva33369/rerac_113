// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:rerac_113/map_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rerac_113/widgets/globals.dart';
import 'package:google_place/google_place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:rerac_113/locationInfo/blk23.dart';
import 'package:rerac_113/locationInfo/blk8.dart';
import 'package:rerac_113/locationInfo/blk72.dart';
import 'package:rerac_113/locationInfo/blk73.dart';
import 'package:rerac_113/locationInfo/blk51.dart';
import 'package:rerac_113/locationInfo/sit.dart';

class MapScreen extends StatefulWidget {
  final DetailsResult? startPosition;
  final DetailsResult? endPosition;

  const MapScreen({Key? key, this.startPosition, this.endPosition})
      : super(key: key);
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late CameraPosition _initialPosition;
  Map<PolylineId, Polyline> polylines = {};
  GoogleMapController? mapController;
  List<dynamic> fullRiskData = [];
  Map riskData = {};
  List<dynamic> waypointData = [];
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> markers = {};
  final Set<Circle> _circles = {};

  @override
  void initState() {
    _determinePosition(); //just for authorisations

    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
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

  //getting data of the 6 locations from the databsase
  _getWaypoint() async {
    final queryParameters = {'request': 'ALL', 'database': 'waypoints'};
    final url = Uri.http(_localhost(), '/get', queryParameters);
    Response response = await get(url);
    setState(() {
      waypointData = jsonDecode(response.body);
    });
  }

  //getting the risk data of the 6 locations from the database
  _getRisk() async {
    final queryParameters = {'request': 'ALL', 'database': 'risks'};
    final url = Uri.http(_localhost(), '/get', queryParameters);
    Response response = await get(url);
    setState(() {
      fullRiskData = jsonDecode(response.body);
      Map risks = jsonDecode(response.body).last;
      risks.removeWhere((key, value) => key == "Date");
      risks.removeWhere((key, value) => key == "Time");
      riskData = risks;
    });
  }

  String _localhost() {
    if (Platform.isAndroid) {
      return IPaddress;
    } else {
      return '127.0.0.1:3000';
    }
  }

  //marker for location to be shown on the map
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  void _setMarker(LatLng point) {
    setState(() {
      markers.add(
        Marker(
          markerId: const MarkerId('marker'),
          position: point,
        ),
      );
    });
  }

  _getGeofence() {
    _getWaypoint();
    List<Geofence> geofenceList = [];
    //this is getting the geofence list locations from the database
    for (int i = 0; i < 6; i++) {
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

  //setting the size of the icon marker to be on the map
  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  //this is to show the bus stop icon on the map
  busStopMarker() async {
    final Uint8List markIcons = await getImages('assets/bus_stop.png', 100);
    // makers added according to index
    markers.add(Marker(
      // given marker id
      markerId: const MarkerId("Bus stop Timings"),
      // given marker icon
      icon: BitmapDescriptor.fromBytes(markIcons),
      // given position
      position: const LatLng(1.332452, 103.777685),
      infoWindow: const InfoWindow(
        // given title for marker
        title: 'Bus Timings',
      ),

      onTap: () {},
    ));
  }

  // This function adds a polyline to the map, connecting the start and end positions.
  _addPolyLine() {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates,
        width: 5);
    // Adds the polyline to the set of polylines on the map.
    polylines[id] = polyline;
    setState(() {});
  }

  // This function gets the polyline between the start and end positions, using the Google Maps Directions API.
  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyCsqrq6bn25yMgMQILghZZ3bVcb29V5ubA',
        // Start position of the polyline.
        PointLatLng(widget.startPosition!.geometry!.location!.lat!,
            widget.startPosition!.geometry!.location!.lng!),

        // End position of the polyline.
        PointLatLng(widget.endPosition!.geometry!.location!.lat!,
            widget.endPosition!.geometry!.location!.lng!),
        travelMode: TravelMode.driving);
    if (result.points.isNotEmpty) {
      // Adds each point of the polyline to the list of polyline coordinates.
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    _addPolyLine();
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

  Future<Position> _determinePosition() async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // not enabled
      return Future.error('Location services are disabled.');
    }

    return await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.bestForNavigation);
  }

  void _onAccelerate(Position position) {
    setState(() {
      velocity = position.speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    rebuildAllChildren(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
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
            myLocationButtonEnabled: false,
            markers: getmarkers(),
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
                        Text("Speed: " + velocity.toStringAsFixed(2),
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
        padding: const EdgeInsets.only(top: 100, right: 0),
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
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.my_location,
                    color: Colors.black,
                  ),
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
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.map_outlined,
                    color: Colors.black,
                  ),
                )),

            Container(
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "speedometer",
                  onPressed: () {},
                  backgroundColor: Colors.white,
                  child: Text(velocity.toStringAsFixed(2),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                )),
          ],
        ),
      ),
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

    markers.add(Marker(
        markerId: MarkerId('start'),
        position: LatLng(widget.startPosition!.geometry!.location!.lat!,
            widget.startPosition!.geometry!.location!.lng!)));
    markers.add(Marker(
        markerId: MarkerId('end'),
        position: LatLng(widget.endPosition!.geometry!.location!.lat!,
            widget.endPosition!.geometry!.location!.lng!)));

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
    _getWaypoint();
    _getRisk();
    Map risk = riskData;

    //markers to place on map
    setState(() {
      for (int i = 0; i < waypointData.length; i++) {
        risk.forEach((key, value) {
          if (waypointData[i]["Name"] == key) {
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
