// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api

import 'dart:convert';
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
import 'package:rerac_113/screens/bus_stop.dart';
import 'package:rerac_113/screens/search_screen.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as web;
import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:rerac_113/notifications.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:text_to_speech/text_to_speech.dart';
import '../locationInfo/blk51.dart';
import 'package:rerac_113/widgets/NavBar.dart';
import 'package:location/location.dart' as loc;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:rerac_113/widgets/globals.dart';
import 'package:rerac_113/screens/bus_stop.dart';
import 'package:intl/src/intl/date_format.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<dynamic> fullRiskData =
      []; // initialising a list for taking in risk data from the database
  Map riskData = {};
  List<dynamic> waypointData =
      []; // initialising a list for taking in location data from the database
  String googleApikey =
      "AIzaSyCsqrq6bn25yMgMQILghZZ3bVcb29V5ubA"; //google API key
  GoogleMapController? mapController; //contrller for Google map
  CameraPosition? cameraPosition;
  LatLng startLocation = const LatLng(1.333099716482213, 103.77543852414324);
  String location = "Search Location";
  int waypointCounter = 0;
  int interval = 30;

  TextToSpeech tts = TextToSpeech(); // setting text to speech variable

  final Completer<GoogleMapController> _controller = Completer();

  final _activityStreamController = StreamController<Activity>.broadcast();
  final _geofenceStreamController = StreamController<Geofence>.broadcast();
  //this code declares a broadcast stream controller that emits events of type Activity.
  //It can be used to create a stream of activity events that multiple parts of an application can subscribe to and receive updates.

  //initialising the variable for the speech to text function
  double volume = 1; // Range: 0-1
  double rate = 1.0; // Range: 0-2
  double pitch = 1.0;

  bool sense = false;

  //this code declares two immutable sets to hold Marker and Circle objects, respectively.
  //These sets can be used to keep track of the markers and circles that are added to a Google Map in a Flutter app.
  final Set<Marker> markers = {};
  final Set<Circle> _circles = {};

  Position? _currentUserPosition;
  double? distanceInMeter = 0.0;

  String text = '';

  //speech to text function
  void speak() {
    tts.setVolume(volume);
    tts.setRate(rate);
    tts.setPitch(pitch);
    tts.speak(text);
  }

  loc.LocationData? currentLocation;

  //get the user's current location
  Future<geo.Position> getUserCurrentLocation() async {
    await geo.Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await geo.Geolocator.requestPermission();

      getUserCurrentLocation().then((value) {});
    });
    return await geo.Geolocator.getCurrentPosition();
  }

  //getting the user's current location for speed calculation
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

  //This function updates the velocity variable in the current state of
  //the widget with the speed value of the input position.
  void _onAccelerate(geo.Position position) {
    //The setState method is called to update the
    //state of the widget with the new value of velocity.
    setState(() {
      velocity = position.speed;
    });
  }

  //this function is mainly for turn by turn navigation but since we do not have access to
  //the sdk, I placed at this screen
  //displays the map and updates the map's position based on the user's current location.
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

    //The setState method is called to update the state of the widget, which will trigger a rebuild of any UI
    //components that depend on the currentLocation variable.
    setState(() {});
  }

  //calculates the distance between the user's current location and
  //the 6 marked off locations
  Future _calculateDistance() async {
    _currentUserPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);

    for (int i = 0; i < 6; i++) {
      distanceInMeter = Geolocator.distanceBetween(
          //using the geolocator package to calculate the distance
          //between the points and the current location to sense whether are they near any of the locations
          _currentUserPosition!.latitude,
          _currentUserPosition!.longitude,
          _geofenceList[i].latitude,
          _geofenceList[i].longitude);
      if (distanceInMeter! <= 25) {
        //sends them a notification once they are less than 25m away from
        //the location
        NotificationService()
            .showNotification(1, "You are nearby", _geofenceList[i].id, 5);
      }
    }
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

  //sends the person's email id, date, time and the speed to the database everytime they exceed the speed limit
  _appendSpeed() async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);
    final data = {
      "date": formattedDate,
      "time": formattedTime,
      "email": globalString,
      "speed": velocity
    };
    final queryParameters = {
      'request': 'APPEND',
      'database': 'speed',
      'data': data
    };
    final url = Uri.http(_localhost(), '/post', queryParameters);
    Response response = await get(url);
  }

  //communicates with a local server
  String _localhost() {
    if (Platform.isAndroid) {
      return IPaddress;
    } else {
      return '127.0.0.1:3000';
    }
  }

  //setting marker
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

  //uses geofencing to trigger actions based on the user's location.
  //The _geofenceList list represents a pre-defined set of locations that the app is monitoring for geofencing events,
  //and the radii around each location determine the specific trigger conditions for each geofence.
  final _geofenceList = <Geofence>[
    Geofence(
      id: 'Blk 51',
      latitude: 1.33207,
      longitude: 103.77436,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 5),
        GeofenceRadius(id: 'radius_100m', length: 25),
        GeofenceRadius(id: 'radius_200m', length: 100),
      ],
    ),
    Geofence(
      id: 'Blk 72',
      latitude: 1.33188,
      longitude: 103.77571,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 5),
        GeofenceRadius(id: 'radius_100m', length: 25),
        GeofenceRadius(id: 'radius_200m', length: 100),
      ],
    ),
    Geofence(
      id: 'Blk 73',
      latitude: 1.33202,
      longitude: 103.77652,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 5),
        GeofenceRadius(id: 'radius_100m', length: 25),
        GeofenceRadius(id: 'radius_200m', length: 100),
      ],
    ),
    Geofence(
      id: 'Blk 23',
      latitude: 1.33398,
      longitude: 103.77530,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 5),
        GeofenceRadius(id: 'radius_100m', length: 25),
        GeofenceRadius(id: 'radius_200m', length: 100),
      ],
    ),
    Geofence(
      id: 'Blk 8',
      latitude: 1.33470,
      longitude: 103.77675,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 5),
        GeofenceRadius(id: 'radius_100m', length: 25),
        GeofenceRadius(id: 'radius_200m', length: 100),
      ],
    ),
    Geofence(
      id: 'SIT',
      latitude: 1.33421,
      longitude: 103.77444,
      radius: [
        GeofenceRadius(id: 'radius_25m', length: 5),
        GeofenceRadius(id: 'radius_100m', length: 25),
        GeofenceRadius(id: 'radius_200m', length: 100),
      ],
    ),
  ];

  //this is getting the geofence list locations from the database
  _getGeofence() {
    _getWaypoint();

    List<Geofence> geofenceList = [];

    for (int i = 0; i < 6; i++) {
      String id = waypointData[i]["Name"];
      double latitude = waypointData[i]["Latitude"].toDouble();
      double longitude = waypointData[i]["Longitude"].toDouble();
      geofenceList.add(
          Geofence(id: id, latitude: latitude, longitude: longitude, radius: [
        GeofenceRadius(id: 'radius_50m', length: 5),
        GeofenceRadius(id: 'radius_150m', length: 25),
        GeofenceRadius(id: 'radius_200m', length: 100),
      ]));
    }
    return geofenceList;
  }

  @override
  Widget build(BuildContext context) {
    rebuildAllChildren(context);

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
            zoom: 17.0, //initial zoom level
          ),
          mapType: MapType.normal,
          markers: getmarkers(),
          circles: _circles,
          onCameraMove: (CameraPosition cameraPosition) {}, //map type
          onMapCreated: (controller) {
            _controller.complete(controller);
            //method called when map is created
            setState(() {
              mapController = controller;
            });
          },
        ),

        _buildGeofenceMonitor(),

        //search autocomplete input
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
                    Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => NavBar()),
                              );
                            },
                            icon: Icon(Icons.menu_sharp)),
                        InkWell(
                            onTap: () async {
                              var place = await PlacesAutocomplete.show(
                                  //autocomplete function to
                                  //help the user type out locations
                                  context: context,
                                  apiKey: googleApikey,
                                  mode: Mode.overlay,
                                  types: [],
                                  strictbounds: false,
                                  components: [
                                    web.Component(web.Component.country, 'sg')
                                  ],
                                  //google_map_webservice package
                                  onError: (err) {});

                              if (place != null) {
                                setState(() {
                                  location = place.description.toString();
                                });

                                //form google_maps_webservice package
                                final plist = web.GoogleMapsPlaces(
                                  apiKey: googleApikey,
                                  apiHeaders: await const GoogleApiHeaders()
                                      .getHeaders(),
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
                                    CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                            target: newlatlang, zoom: 17)));
                              }
                            },
                            //creates a user interface element that displays a card with a location search button,
                            //allowing the user to search for a location within the app.
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Card(
                                child: Container(
                                    padding: const EdgeInsets.all(0),
                                    width:
                                        MediaQuery.of(context).size.width - 110,
                                    child: ListTile(
                                      title: Text(
                                        location,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      trailing: const Icon(Icons.search),
                                      dense: true,
                                    )),
                              ),
                            )),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),

      //to display the buttons at the side of the map
      floatingActionButton: Container(
        padding: const EdgeInsets.only(top: 50, right: 0),
        alignment: Alignment.topRight,
        child: Column(
          //will break to another line on overflow
          //use vertical to show  on vertical axis
          children: <Widget>[
            Container(
                margin: const EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "currentLocation",
                  onPressed: () {
                    //brings the user to the his/her current location when pressed on the button
                    getUserCurrentLocation().then((value) async {
                      // specified current users location
                      CameraPosition cameraPosition = CameraPosition(
                        target: LatLng(value.latitude, value.longitude),
                        zoom: 18,
                      );

                      //it moves around the camera to user's current location
                      final GoogleMapController controller =
                          await _controller.future;
                      controller.animateCamera(
                          CameraUpdate.newCameraPosition(cameraPosition));
                      setState(() {});
                    });
                    //   //action code for button 1
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.black,
                  ),
                )), //button first

            Container(
                margin: const EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "destination",
                  onPressed: () {
                    //brings the user to search origin and destination page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.add,
                    color: Colors.black,
                  ),
                )),
            //shows the user the speed that they are travelling at
            Container(
                margin: const EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: "speed",
                  onPressed: () {},
                  backgroundColor: Colors.white,
                  child: Text(
                    velocity.toStringAsFixed(2),
                    style: TextStyle(color: Colors.black),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
    busStopMarker();
    _calculateDistance();
    //just for authorisations

    tz.initializeTimeZones();

    geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      //distanceFilter: 0,
    )).listen((Position position) {
      _onAccelerate(position);
    });
    //Registers event listeners for geofence service state changes, such as geofence status changes,
    //location changes, activity changes,
    //and stream errors, and starts the geofence service with the specified geofence list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
      geofenceService.addLocationChangeListener(_onLocationChanged);
      geofenceService.addLocationServicesStatusChangeListener(
          _onLocationServicesStatusChanged);
      geofenceService.addActivityChangeListener(_onActivityChanged);
      geofenceService.addStreamErrorListener(_onError);
      geofenceService.start(_geofenceList).catchError(_onError);
    });
  }

  //This will mark the root element and all its child elements as needing to be rebuilt,
  //which will trigger a rebuild of the entire widget tree.
  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
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
    final Uint8List markIcons = await getImages('assets/bus_stop.png', 120);
    // makers added according to index
    markers.add(Marker(
      // given marker id
      markerId: const MarkerId("Bus stop Timings"),
      // given marker icon
      icon: BitmapDescriptor.fromBytes(markIcons),
      // given position
      position: const LatLng(1.33242, 103.77769),
      infoWindow: const InfoWindow(
        // given title for marker
        title: 'Bus Timings',
      ),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const BusStop()), //brings them to a page to show
          //bus timmings for that location
        );
      },
    ));
  }

  Widget buildContentView() {
    return ListView(
      //provides a scroll behavior that "bounces" when the user reaches the end of the list
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      children: const [
        Home(),
      ],
    );
  }

  //it is used to configure various settings related to geofencing
  final geofenceService = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 1000,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 10000,
      useActivityRecognition: true,
      allowMockLocations: true,
      printDevLog: false,
      geofenceRadiusSortType: GeofenceRadiusSortType.DESC);

  Future<void> _onGeofenceStatusChanged(
      Geofence geofence,
      GeofenceRadius geofenceRadius,
      GeofenceStatus geofenceStatus,
      Location location) async {
    //it prints the JSON representation of the geofence, geofenceRadius,
    //and geofenceStatus objects to the console for debugging purposes,
    final geofenceJson = geofence.toJson();
    print('geofence: $geofenceJson');
    print('geofence: ${geofence.toJson()}');
    print('geofence: ${geofence.toString()}');
    print('geofenceRadius: ${geofenceRadius.toJson()}');
    print('geofenceStatus: ${geofenceStatus.toString()}');
    //geofence object to a StreamController using the sink.add() method
    _geofenceStreamController.sink.add(geofence);
    //The StreamController is used to send events to listeners that are
    //interested in changes to the geofence status.

    // (this to check if the it takes in Json format)
    // if (geofenceJson["id"] == "blk51") {
    //   speak("you are entering blk 51");
    //   NotificationService()
    //       .showNotification(1, "Location nearby", geofenceJson["id"], 5);
    // }
    // if (geofenceJson["id"] == "blk72") {
    //   speak("you are entering blk 72");
    //   NotificationService()
    //       .showNotification(1, "Location nearby", geofenceJson["id"], 5);
    // }

    // if (geofenceJson["id"] == 'clementi_mall') {
    //   print("We are not at makan place");
    // }
  }

  // this function is to be called when the user's activity has changed.
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

  //The purpose of this method is to handle errors that may occur during the execution of the geofencing service.
  void _onError(error) {
    final errorCode = getErrorCodesFromError(error);
    if (errorCode == null) {
      print('Undefined error: $error');
      return;
    }

    print('ErrorCode: $errorCode');
  }

  //
  addMarkers(img, location, id) async {
    // Load marker icon from asset image
    BitmapDescriptor markerbitmap = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      img,
    );

    // Define a map of waypoint functions, where each key is a waypoint name and the corresponding value is a function that can be called when the waypoint marker is tapped
    const Map waypointFunction = {
      "Blk 8": Blk8(),
      "Blk 23": Blk23(),
      "Blk 72": Blk72(),
      "Blk 73": Blk73(),
      "Blk 51": Blk51(),
      "SIT": SIT()
    };

    // Add a new marker to the list of markers
    markers.add(Marker(
      // Marker ID, must be unique
      markerId: MarkerId(id.toString()),
      // Marker position, where it will be displayed on the map
      position: location,
      // Function called when the marker is tapped
      onTap: () {
        // Loop through the list of waypoint data and find the waypoint with the matching name
        for (int i = 0; i < waypointData.length; i++) {
          if (id == waypointData[i]["Name"]) {
            // Navigate to the waypoint screen using the function from the map
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => waypointFunction[id]));
            // Animate the camera to focus on the waypoint
            mapController?.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                    target: LatLng(waypointData[i]["Latitude"],
                        waypointData[i]["Longitude"]),
                    zoom: 17)));
          }
        }
      },
      // Marker icon
      icon: markerbitmap,
    ));
  }

  @override
  // This method is used to dispose of the stream controllers once they are no longer needed
  void dispose() {
    _activityStreamController.close();
    _geofenceStreamController.close();
    super.dispose();
  }

  Widget _buildGeofenceMonitor() {
    interval++;
    // This widget uses a StreamBuilder to listen for updates to the geofence stream
    return StreamBuilder<Geofence>(
      stream: _geofenceStreamController.stream,
      builder: (context, snapshot) {
        // final updatedDateTime = DateTime.now();
        final content = snapshot.data?.toJson();
        // If the content of the snapshot is null, display an empty column widget
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
          for (int i = 0; i < 6; i++) {
            _getRisk();
            var backgroundColor = Colors.grey;
            distanceInMeter = Geolocator.distanceBetween(
                //using goelocator package to track whether
                //are they near one of the locations
                _currentUserPosition!.latitude,
                _currentUserPosition!.longitude,
                _geofenceList[i].latitude,
                _geofenceList[i].longitude);
            if (distanceInMeter! <= 100 && distanceInMeter! > 25) {
              //sends them a notification when they are 100m away from the location
              NotificationService().showNotification(
                  1, "You are 100m away", _geofenceList[i].id, 5);
            } else if (distanceInMeter! <= 25) {
              //sends them a notification and a voice alert when they are less than 25m away
              NotificationService().showNotification(
                  2, "You are nearby", _geofenceList[i].id, 5);

              //assigns the variables; color and texts accordingly to the risks
              riskData.forEach((key, value) {
                if (_geofenceList[i].id == key) {
                  if (value >= 1 && value <= 3) {
                    text = 'You are entering a low risk zone';
                    backgroundColor = Colors.green;
                  } else if (value >= 4 && value <= 7) {
                    text = 'You are entering a medium risk zone';
                    backgroundColor = Colors.orange;
                  } else if (value >= 8 && value <= 10) {
                    text = 'You are entering a high risk zone';
                    backgroundColor = Colors.red;
                  } else {
                    backgroundColor = Colors.grey;
                  }
                }
              });
            }

            //the geofencing continuosly runs to check their location and assigns them the text messages
            //hence the voice alerts overlap. therefore, need to set intervals inbetween to make them sound smoother
            if (interval > 30) {
              speak();
              print("spoken");
              if (velocity > 1) {
                text = 'Slow down. You are going very fast';
                speak();
                print('spoken');
                _appendSpeed();
              }
              interval = 0;
            }

            // this is the warning icon to show the user when they entering the zones
            return Container(
                padding: const EdgeInsets.only(top: 263, right: 15),
                alignment: Alignment.topRight,
                margin: const EdgeInsets.all(10),
                child: FloatingActionButton(
                  heroTag: content['id'],
                  onPressed: () {},
                  backgroundColor: backgroundColor,
                  child: const Icon(Icons.warning_amber),
                ));
          }
        }
        return Container();
      },
    );
  }

  // This loop iterates over the waypoints and compares the names to the risk data.
  Set<Marker> getmarkers() {
    _getWaypoint();
    _getRisk();
    //_calculateDistance();
    Map risk = riskData;

    //markers to place on map
    setState(() {
      for (int i = 0; i < waypointData.length; i++) {
        risk.forEach((key, value) {
          if (waypointData[i]["Name"] == key) {
            // This block sets the color and image for the marker based on the risk value.
            String assets = 'assets/greenSmile.png';
            Color fillColor = Colors.blueGrey.withOpacity(0.5);
            Color strokeColor = Colors.blueGrey;
            if (value >= 1 && value <= 3) {
              fillColor = Colors.greenAccent.withOpacity(0.5);
              strokeColor = Colors.greenAccent;
              assets = 'assets/greenSmile.png';
            } else if (value >= 4 && value <= 7) {
              fillColor = Colors.orangeAccent.withOpacity(0.5);
              strokeColor = Colors.orangeAccent;
              assets = 'assets/orangeSmile.png';
            } else if (value >= 8 && value <= 10) {
              fillColor = Colors.redAccent.withOpacity(0.5);
              strokeColor = Colors.redAccent;
              assets = 'assets/redSmile.png';
            }
            // This adds the marker to the map using the marker image and location.
            addMarkers(
                assets,
                LatLng(
                    waypointData[i]["Latitude"], waypointData[i]["Longitude"]),
                key);
            // This adds a circle to the map around the marker to indicate the risk level.
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
