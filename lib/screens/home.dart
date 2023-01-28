import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rerac_113/locationInfo/blk23.dart';
import 'package:rerac_113/locationInfo/blk72.dart';
import 'package:rerac_113/locationInfo/blk73.dart';
import 'package:rerac_113/locationInfo/blk8.dart';
import 'package:rerac_113/locationInfo/sit.dart';
import 'package:rerac_113/screens/search_screen.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as web;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:rerac_113/notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:geofence_service/geofence_service.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:text_to_speech/text_to_speech.dart';
import '../locationInfo/blk51.dart';
import 'package:rerac_113/widgets/speedometer_container.dart';
import 'package:rerac_113/widgets/NavBar.dart';
import 'package:location/location.dart' as loc;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map riskData = {};
  List<dynamic> waypointData = [];
  String googleApikey = "AIzaSyCsqrq6bn25yMgMQILghZZ3bVcb29V5ubA";
  GoogleMapController? mapController; //contrller for Google map
  CameraPosition? cameraPosition;
  LatLng startLocation = LatLng(1.33206, 103.77436);
  String location = "Search Location";
  int waypointCounter = 0;

  TextToSpeech tts = TextToSpeech();

  Completer<GoogleMapController> _controller = Completer();

  final _activityStreamController = StreamController<Activity>.broadcast();
  final _geofenceStreamController = StreamController<Geofence>.broadcast();

  String text = '';
  double volume = 1; // Range: 0-1
  double rate = 1.0; // Range: 0-2
  double pitch = 1.0;

  double velocity = 0.0;

  bool sense = false;
  final Set<Marker> markers = new Set();
  final Set<Circle> _circles = new Set();

  void speak() {
    tts.setVolume(volume);
    tts.setRate(rate);
    tts.setPitch(pitch);
    tts.speak(text);
  }

  loc.LocationData? currentLocation;

  Future<geo.Position> getUserCurrentLocation() async {
    await geo.Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await geo.Geolocator.requestPermission();
      print("ERROR" + error.toString());

      getUserCurrentLocation().then((value) {
        print(value.latitude.toString() + value.longitude.toString());
      });
    });
    return await geo.Geolocator.getCurrentPosition();
  }

  Future<geo.Position> _determinePosition() async {
    bool serviceEnabled;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // not enabled
      return Future.error('Location services are disabled.');
    }

    return await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.bestForNavigation);
  }

  void _onAccelerate(geo.Position position) {
    setState(() {
      velocity = position.speed;
    });
  }

  void getCurrentLocation() async {
    loc.Location location = loc.Location();
    location.getLocation().then(
      (location) {
        currentLocation = location;
      },
    );
    GoogleMapController googleMapController = await _controller.future;

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;

      googleMapController
          .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        zoom: 13.5,
        target: LatLng(
          newLoc.latitude!,
          newLoc.longitude!,
        ),
      )));
      setState(() {});
    });

    // markers.add(
    //   Marker(
    //     markerId: const MarkerId("currentLocation"),
    //     icon: currentLocationIcon,
    //     position:
    //         LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
    //   ),
    // );
    setState(() {});
  }

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
      return '192.168.1.26:3000';
    } else {
      return '127.0.0.1:3000';
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _determinePosition(); //just for authorisations

    geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      //distanceFilter: 0,
    )).listen((Position position) {
      _onAccelerate(position);
    });
  }

  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  currentLocIcon() async {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration.empty, "assets/camera.png")
        .then(
      (icon) {
        currentLocationIcon = icon;
      },
    );
  }

  void _setMarker(LatLng point) {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId('marker'),
          position: point,
        ),
      );
    });
  }

  _getGeofence() {
    List<Geofence> geofenceList = [];

    for (int i = 0; i < 6; i++) {
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

  // This function is to be called when a location services status change occurs
  // since the service was started.
  // final _geofenceList = <Geofence>[
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
  //   Geofence(
  //     id: 'blk51',
  //     latitude: 37.4220936,
  //     longitude: -122.083922,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 200),
  //       GeofenceRadius(id: 'radius_100m', length: 250),
  //       GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'blk72',
  //     latitude: 1.3318895388375338,
  //     longitude: 103.77571465588211,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 200),
  //       GeofenceRadius(id: 'radius_100m', length: 250),
  //       GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'blk73',
  //     latitude: 1.3320323222018304,
  //     longitude: 103.77649335992052,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 200),
  //       GeofenceRadius(id: 'radius_100m', length: 250),
  //       GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'blk23',
  //     latitude: 1.3339717453574258,
  //     longitude: 103.77531565381817,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 200),
  //       GeofenceRadius(id: 'radius_100m', length: 250),
  //       GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'blk8',
  //     latitude: 1.334792177762611,
  //     longitude: 103.77629441346048,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 200),
  //       GeofenceRadius(id: 'radius_100m', length: 250),
  //       GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'sit',
  //     latitude: 1.3342380695589044,
  //     longitude: 103.7744542762125,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 200),
  //       GeofenceRadius(id: 'radius_100m', length: 250),
  //       GeofenceRadius(id: 'radius_200m', length: 300),
  //     ],
  //   ),
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(),
      body: Stack(children: [
        GoogleMap(
          //Map widget from google_maps_flutter package
          zoomControlsEnabled: true,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          zoomGesturesEnabled: true,
          myLocationButtonEnabled: false,
          myLocationEnabled: true, //enable Zoom in, out on map
          initialCameraPosition: CameraPosition(
            //innital position in map
            target: startLocation, //initial position
            zoom: 18.0, //initial zoom level
          ),
          mapType: MapType.normal,
          markers: getmarkers(),
          circles: _circles,
          onCameraMove: (CameraPosition cameraPosition) {
            print(cameraPosition.zoom);
          }, //map type
          onMapCreated: (controller) {
            _controller.complete(controller);
            //method called when map is created
            setState(() {
              mapController = controller;
            });
          },
        ),

        _buildGeofenceMonitor(),
        //Notifications(),

        //search autoconplete input
        Positioned(
          //search input bar
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
                    const Text(
                      'Welcome to RERAC!',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                        onTap: () async {
                          var place = await PlacesAutocomplete.show(
                              context: context,
                              apiKey: googleApikey,
                              mode: Mode.overlay,
                              types: [],
                              strictbounds: false,
                              components: [
                                web.Component(web.Component.country, 'sg')
                              ],
                              //google_map_webservice package
                              onError: (err) {
                                print(err);
                              });

                          if (place != null) {
                            setState(() {
                              location = place.description.toString();
                            });

                            //form google_maps_webservice package
                            final plist = web.GoogleMapsPlaces(
                              apiKey: googleApikey,
                              apiHeaders: await GoogleApiHeaders().getHeaders(),
                              //from google_api_headers package
                            );
                            String placeid = place.placeId ?? "0";
                            final detail =
                                await plist.getDetailsByPlaceId(placeid);
                            final geometry = detail.result.geometry!;
                            final lat = geometry.location.lat;
                            final lang = geometry.location.lng;
                            var newlatlang = LatLng(lat, lang);

                            _setMarker(LatLng(
                                newlatlang.latitude, newlatlang.longitude));

                            //move map camera to selected place with animation
                            mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(CameraPosition(
                                    target: newlatlang, zoom: 17)));
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Card(
                            child: Container(
                                padding: EdgeInsets.all(0),
                                width: MediaQuery.of(context).size.width - 40,
                                child: ListTile(
                                  title: Text(
                                    location,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  trailing: Icon(Icons.search),
                                  dense: true,
                                )),
                          ),
                        ))
                  ],
                ),
              ),
            ),
          ),
        ),
        //Notifications(),
        //alignment: const Alignment(5, 50),
      ]),
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
                  heroTag: "currentLocation",
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
                  heroTag: "destination",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    );
                  },
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.add),
                )),
            Container(
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "speed",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SpeedometerContainer()),
                    );
                  },
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Text(velocity.toStringAsFixed(2)),
                )),
          ],
        ),
      ),
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

  Widget _buildContentView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      children: [
        Home(),
      ],
    );
  }

  final _geofenceService = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 10000,
      useActivityRecognition: true,
      allowMockLocations: false,
      printDevLog: false,
      geofenceRadiusSortType: GeofenceRadiusSortType.DESC);

  Future<void> _onGeofenceStatusChanged(
      Geofence geofence,
      GeofenceRadius geofenceRadius,
      GeofenceStatus geofenceStatus,
      Location location) async {
    final geofenceJson = geofence.toJson();
    print('geofence: $geofenceJson');
    print('geofence: ${geofence.toJson()}');
    print('geofence: ${geofence.toString()}');
    print('geofenceRadius: ${geofenceRadius.toJson()}');
    print('geofenceStatus: ${geofenceStatus.toString()}');
    _geofenceStreamController.sink.add(geofence);
    if (geofenceJson["id"] == 'blk51') {
      print("We are at the location!");
    }
    if (geofenceJson["id"] == 'clementi_mall') {
      print("We are not at makan place");
    }
  }

  void _onActivityChanged(Activity prevActivity, Activity currActivity) {
    print('prevActivity: ${prevActivity.toJson()}');
    print('currActivity: ${currActivity.toJson()}');
    _activityStreamController.sink.add(currActivity);
  }

  // This function is to be called when the location has changed.
  void _onLocationChanged(Location location) {
    print('location: ${location.toJson()}');
  }

  // This function is to be called when a location services status change occurs
  // since the service was started.
  void _onLocationServicesStatusChanged(bool status) {
    print('isLocationServicesEnabled: $status');
  }

  // This function is used to handle errors that occur in the service.
  void _onError(error) {
    final errorCode = getErrorCodesFromError(error);
    if (errorCode == null) {
      print('Undefined error: $error');
      return;
    }

    print('ErrorCode: $errorCode');
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
        if (id == 'blk8') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk8()));
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(1.334792177762611, 103.77629441346048),
                  zoom: 17)
              //17 is new zoom level
              ));
        } else if (id == 'blk23') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk23()));
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(37.4220936, -122.083922), zoom: 17)
              //17 is new zoom level
              ));
        } else if (id == 'blk51') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk51()));
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(37.4220936, -122.083922), zoom: 17)
              //17 is new zoom level
              ));
        } else if (id == 'blk72') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk72()));
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(1.3318895388375338, 103.77571465588211),
                  zoom: 17)
              //17 is new zoom level
              ));
        } else if (id == 'blk73') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => blk73()));
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(1.3320323222018304, 103.77649335992052),
                  zoom: 17)
              //17 is new zoom level
              ));
        } else if (id == 'sit') {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => sit()));
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(1.3342380695589044, 103.7744542762125),
                  zoom: 17)
              //17 is new zoom level
              ));
        }
      },
      icon: markerbitmap, //Icon for Marker
    ));
  }

  @override
  void dispose() {
    _activityStreamController.close();
    _geofenceStreamController.close();
    super.dispose();
  }

  Widget _buildGeofenceMonitor() {
    return StreamBuilder<Geofence>(
      stream: _geofenceStreamController.stream,
      builder: (context, snapshot) {
        // final updatedDateTime = DateTime.now();
        final content = snapshot.data?.toJson();
        // ignore: unnecessary_null_comparison
        if (content == null) {
          @override
          const content = '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              //   Text('•\t\tGeofence (updated: $updatedDateTime)'),
              SizedBox(height: 50.0),
              Text(content)
            ],
          );
        } else {
          String location = "";
          if (content['id'] == 'blk51') {
            location = "We are at the location.";
            text = 'You are inside the geofenced area: Block 51';
            NotificationService()
                .showNotification(1, "GeoFenced Area", "BLock 51", 5);
            speak();
            return Container(
                padding: const EdgeInsets.only(top: 263, right: 15),
                alignment: Alignment.topRight,
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "blk51",
                  onPressed: () {},
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.warning_amber),
                ));
          }

          if (content['id'] == 'blk8') {
            location = "We are at the location.";
            text = 'You are inside the geofenced area: Block 8';
            NotificationService()
                .showNotification(1, "GeoFenced Area", "BLock 8", 5);
            speak();
            return Container(
                padding: const EdgeInsets.only(top: 263, right: 15),
                alignment: Alignment.topRight,
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "blk8",
                  onPressed: () {},
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.warning_amber),
                ));
          }

          if (content['id'] == 'blk72') {
            location = "We are at the location.";
            text = 'You are inside the geofenced area: Block 72';
            NotificationService()
                .showNotification(1, "GeoFenced Area", "BLock 72", 5);
            speak();
            return Container(
                padding: const EdgeInsets.only(top: 263, right: 15),
                alignment: Alignment.topRight,
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "blk72",
                  onPressed: () {},
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.warning_amber),
                ));
          }

          if (content['id'] == 'blk73') {
            location = "We are at the location.";
            text = 'You are inside the geofenced area: Block 73';
            NotificationService()
                .showNotification(1, "GeoFenced Area", "BLock 73", 5);
            speak();
            return Container(
                padding: const EdgeInsets.only(top: 263, right: 15),
                alignment: Alignment.topRight,
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "blk73",
                  onPressed: () {},
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.warning_amber),
                ));
          }

          if (content['id'] == 'sit') {
            location = "We are at the location.";
            text = 'You are inside the geofenced area: sit';
            NotificationService()
                .showNotification(1, "GeoFenced Area", "sit", 5);
            speak();
            return Container(
                padding: const EdgeInsets.only(top: 263, right: 15),
                alignment: Alignment.topRight,
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "sit",
                  onPressed: () {},
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.warning_amber),
                ));
          }

          if (content['id'] == 'blk23') {
            location = "We are at the location.";
            text = 'You are inside the geofenced area: Block 23';
            NotificationService()
                .showNotification(1, "GeoFenced Area", "BLock 23", 5);
            speak();
            return Container(
                padding: const EdgeInsets.only(top: 263, right: 15),
                alignment: Alignment.topRight,
                margin: EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "blk23",
                  onPressed: () {},
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.warning_amber),
                ));
          }
        }
        return Container();
      },
    );
  }

  Widget _buildActivityMonitor() {
    return StreamBuilder<Activity>(
      stream: _activityStreamController.stream,
      builder: (context, snapshot) {
        final updatedDateTime = DateTime.now();
        final content = snapshot.data?.toJson().toString() ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Text('•\t\tActivity (updated: $updatedDateTime)'),
            const SizedBox(height: 50.0),
            Text(content),
          ],
        );
      },
    );
  }

  Set<Marker> getmarkers() {
    _getWaypoint();
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
}
