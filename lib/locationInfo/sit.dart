// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

/*
Name: Akshath Jain
Date: 3/18/2019 - 4/26/2021
Purpose: Example app that implements the package: sliding_up_panel
Copyright: © 2021, Akshath Jain. All rights reserved.
Licensing: More information can be found here: https://github.com/akshathjain/sliding_up_panel/blob/master/LICENSE
*/

import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rerac_113/screens/home.dart';
import 'package:rerac_113/screens/markerInfo.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rerac_113/widgets/panel_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as web;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:live_location_tracking_distance_awareness/geofencing.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/gestures.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:rerac_113/screens/search_screen.dart';
//import 'package:geofence/geofence/geofence.dart';

import 'package:geofence_service/geofence_service.dart';
import 'package:rerac_113/widgets/slide_up.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';

class sit extends StatefulWidget {
  const sit({super.key});

  @override
  State<sit> createState() => _sitState();
}

class _sitState extends State<sit> {
  Map RiskData = {};
  List<Map> FullRiskData = [];
  List<dynamic> waypointData = [];
  BorderRadiusGeometry radius = const BorderRadius.only(
    topLeft: Radius.circular(24.0),
    topRight: Radius.circular(24.0),
  );
  GoogleMapController? mapController; //contrller for Google map
  CameraPosition? cameraPosition;
  final _geofenceStreamController = StreamController<Geofence>.broadcast();

  final Set<Marker> markers = new Set();
  final Set<Circle> _circles = new Set();
  int waypointCounter = 0;

  late List<riskData> _chartData;
  late TooltipBehavior _tooltipBehavior;
  String risknum_sit = '0';

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
      final risks = jsonDecode(response.body);
      FullRiskData = risks;
      RiskData = risks.last;
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

  String _localhost() {
    if (Platform.isAndroid) {
      return '192.168.1.26:3000';
    } else {
      return '127.0.0.1:3000';
    }
  }

  @override
  void initState() {
    _chartData = getChartData();
    _tooltipBehavior = TooltipBehavior(enable: true);
    super.initState();
  }

  getmarkers() {
    _getWaypoint();
    _getRisk();
    var risknum = {
      _getGeofence()[0].id.toString(): RiskData["Blk 51"].toString(),
      _getGeofence()[1].id.toString(): RiskData["Blk 72"].toString(),
      _getGeofence()[2].id.toString(): RiskData["Blk 73"].toString(),
      _getGeofence()[3].id.toString(): RiskData["Blk 23"].toString(),
      _getGeofence()[4].id.toString(): RiskData["Blk 8"].toString(),
      _getGeofence()[5].id.toString(): RiskData["SIT"].toString(),
    };

    //markers to place on map
    setState(() {
      for (int i = 0; i < 6; i++) {
        if (_getGeofence()[i].id.toString() == 'sit') {
          risknum_sit == risknum[_getGeofence()[i].id.toString()];
        }
        if (risknum[_getGeofence()[i].id.toString()] == '1') {
          String location =
              LatLng(_getGeofence()[i].latitude, _getGeofence()[i].longitude)
                  .toString();
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(
                      _getGeofence()[i].latitude, _getGeofence()[i].longitude),
                  zoom: 17)));

          String locName = _getGeofence()[i].id.toString();
        } else if (risknum[_getGeofence()[i].id.toString()] == '2') {
          String location =
              LatLng(_getGeofence()[i].latitude, _getGeofence()[i].longitude)
                  .toString();
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(
                      _getGeofence()[i].latitude, _getGeofence()[i].longitude),
                  zoom: 17)));

          String locName = _getGeofence()[i].id.toString();
        } else if (risknum[_getGeofence()[i].id.toString()] == '3') {
          String location =
              LatLng(_getGeofence()[i].latitude, _getGeofence()[i].longitude)
                  .toString();
          mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(
                      _getGeofence()[i].latitude, _getGeofence()[i].longitude),
                  zoom: 17)));

          String locName = _getGeofence()[i].id.toString();
        }
      }

      //add more markers here
    });
  }

  @override
  Widget build(BuildContext context) {
    _getWaypoint();
    _getRisk();
    var risknum = {
      _getGeofence()[0].id.toString(): RiskData["Blk 51"].toString(),
      _getGeofence()[1].id.toString(): RiskData["Blk 72"].toString(),
      _getGeofence()[2].id.toString(): RiskData["Blk 73"].toString(),
      _getGeofence()[3].id.toString(): RiskData["Blk 23"].toString(),
      _getGeofence()[4].id.toString(): RiskData["Blk 8"].toString(),
      _getGeofence()[5].id.toString(): RiskData["SIT"].toString(),
    };
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
        panel: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    "Risk Evaluation: ${risknum[_getGeofence()[5].id.toString()]!}",
                    style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0), fontSize: 30),
                  ),
                  ImageSlideshow(
                    indicatorColor: Colors.blue,
                    onPageChanged: (value) {
                      debugPrint('Page changed: $value');
                    },
                    autoPlayInterval: 3000,
                    isLoop: true,
                    children: [
                      Image.asset(
                        'assets/blk8_1.png',
                        fit: BoxFit.cover,
                      ),
                      Image.asset(
                        'assets/blk8_2.png',
                        fit: BoxFit.cover,
                      ),
                      Image.asset(
                        'assets/blk8_3.png',
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                  SfCartesianChart(
                    title: ChartTitle(text: 'Hourly risk analysis'),
                    legend: Legend(isVisible: true),
                    tooltipBehavior: _tooltipBehavior,
                    series: <ChartSeries>[
                      LineSeries<riskData, String>(
                          name: 'Vehicles',
                          dataSource: _chartData,
                          xValueMapper: (riskData risks, _) => risks.time,
                          yValueMapper: (riskData risks, _) => risks.risks,
                          dataLabelSettings: DataLabelSettings(isVisible: true),
                          enableTooltip: true),
                    ],
                    primaryXAxis: NumericAxis(
                        edgeLabelPlacement: EdgeLabelPlacement.shift),
                    primaryYAxis:
                        NumericAxis(numberFormat: NumberFormat.compact()),
                  ),
                ],
              ),
            ),
          ),
        ),
        collapsed: Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: radius,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 250,
                child: const Center(
                  child: Text(
                    "SiT",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(
                width: 142.5,
                child: Center(
                  child: Text(
                    risknum[_getGeofence()[5].id.toString()]!,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: const markerInfo(),
        borderRadius: radius,
      ),
    );
  }

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
  //     latitude: 1.34683,
  //     longitude: 103.69919,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 25),
  //       GeofenceRadius(id: 'radius_100m', length: 100),
  //       GeofenceRadius(id: 'radius_200m', length: 200),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'blk72',
  //     latitude: 1.3318895388375338,
  //     longitude: 103.77571465588211,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 25),
  //       GeofenceRadius(id: 'radius_100m', length: 100),
  //       GeofenceRadius(id: 'radius_200m', length: 200),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'blk73',
  //     latitude: 1.3320323222018304,
  //     longitude: 103.77649335992052,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 25),
  //       GeofenceRadius(id: 'radius_100m', length: 100),
  //       GeofenceRadius(id: 'radius_200m', length: 200),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'blk23',
  //     latitude: 1.3339717453574258,
  //     longitude: 103.77531565381817,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 25),
  //       GeofenceRadius(id: 'radius_100m', length: 100),
  //       GeofenceRadius(id: 'radius_200m', length: 200),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'blk8',
  //     latitude: 1.334792177762611,
  //     longitude: 103.77629441346048,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 25),
  //       GeofenceRadius(id: 'radius_100m', length: 100),
  //       GeofenceRadius(id: 'radius_200m', length: 200),
  //     ],
  //   ),
  //   Geofence(
  //     id: 'sit',
  //     latitude: 1.3342380695589044,
  //     longitude: 103.7744542762125,
  //     radius: [
  //       GeofenceRadius(id: 'radius_25m', length: 25),
  //       GeofenceRadius(id: 'radius_100m', length: 100),
  //       GeofenceRadius(id: 'radius_200m', length: 200),
  //     ],
  //   ),
  // ];

  List<riskData> getChartData() {
    List<riskData> chartData = [];
    for (int i = 0; i < FullRiskData.length; i++) {
      chartData.add(riskData(FullRiskData[i]["SIT"], FullRiskData[i]["Time"]));
    }

    return chartData;
  }
}

class riskData {
  riskData(this.risks, this.time);
  final double risks;
  final String time;
}
