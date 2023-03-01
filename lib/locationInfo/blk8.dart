// ignore_for_file: depend_on_referenced_packages, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rerac_113/screens/home.dart';
import 'package:rerac_113/screens/markerInfo.dart';
import 'package:rerac_113/widgets/globals.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';

class Blk8 extends StatefulWidget {
  const Blk8({super.key});

  @override
  State<Blk8> createState() => Blk8State();
}

class Blk8State extends State<Blk8> {
  List<dynamic> fullRiskData = [];
  Map riskData = {};
  List<dynamic> waypointData = [];
  Map<dynamic, dynamic> AverageRisk = {};
  BorderRadiusGeometry radius = const BorderRadius.only(
    topLeft: Radius.circular(24.0),
    topRight: Radius.circular(24.0),
  );
  GoogleMapController? mapController; //contrller for Google map
  CameraPosition? cameraPosition;

  final Set<Marker> markers = {};

  late List<RiskData> _chartData;
  late TooltipBehavior _tooltipBehavior;

  Color textColor = Colors.green;

  getColor(String value) {
    if (value == 'Low Risk') {
      textColor = Colors.green;
    } else if (value == 'Medium Risk') {
      textColor = Colors.orange;
    } else if (value == 'High Risk') {
      textColor == Colors.red;
    }

    return textColor;
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
        fullRiskData = jsonDecode(response.body);
        riskData = fullRiskData.last;
      });
    }
  }

  _getAveRisk() async {
    final queryParameters = {'request': 'ALL', 'database': 'average_risks'};
    final url = Uri.http(_localhost(), '/get', queryParameters);
    Response response = await get(url);
    setState(() {
      AverageRisk = jsonDecode(response.body).last;
    });
  }

  String _localhost() {
    if (Platform.isAndroid) {
      return IPaddress;
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _getWaypoint();
    _getRisk();
    _getAveRisk();
    Map risk = riskData;
    int blk8Risk = risk["Blk 8"];

    _chartData = getChartData();

    rebuildAllChildren(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(
                context, MaterialPageRoute(builder: (context) => Home()));
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
      body: SlidingUpPanel(
        panel: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    "Location: Block 8",
                    style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0), fontSize: 30),
                  ),
                  Text("Current risk: " + getRisk(blk8Risk)),
                  Text("Average risk for the day: " +
                      AverageRisk['Blk 8'].toString()),
                  SfCartesianChart(
                    title: ChartTitle(text: 'Hourly risk analysis'),
                    legend: Legend(isVisible: true),
                    tooltipBehavior: _tooltipBehavior,
                    series: <ChartSeries>[
                      LineSeries<RiskData, int>(
                          name: 'Risk number',
                          dataSource: _chartData,
                          xValueMapper: (RiskData risks, _) => risks.time,
                          yValueMapper: (RiskData risks, _) => risks.risks,
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: true),
                          enableTooltip: true),
                    ],
                    primaryXAxis: NumericAxis(
                        edgeLabelPlacement: EdgeLabelPlacement.shift),
                    primaryYAxis:
                        NumericAxis(numberFormat: NumberFormat.compact()),
                  ),
                  ImageSlideshow(
                    indicatorColor: Colors.blue,
                    isLoop: true,
                    children: [
                      Image.asset(
                        'assets/blk8_1.png',
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        collapsed: Container(
          decoration: BoxDecoration(
            color: (blk8Risk >= 1 && blk8Risk <= 3)
                ? Colors.green
                : (blk8Risk >= 4 && blk8Risk <= 7)
                    ? Colors.orange
                    : (blk8Risk >= 8 && blk8Risk <= 10)
                        ? Colors.red
                        : Colors.grey,
            borderRadius: radius,
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 250,
                child: Center(
                  child: Text(
                    "Block 8",
                    style: TextStyle(color: Colors.white, fontSize: 30),
                  ),
                ),
              ),
              SizedBox(
                width: 142.5,
                child: Center(
                  child: Text(
                    getRisk(blk8Risk),
                    style: const TextStyle(color: Colors.white, fontSize: 30),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: const MarkerInfo(),
        borderRadius: radius,
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

  List<RiskData> getChartData() {
    _getRisk();
    String dateNow = DateFormat("yyyy-MM-dd").format(DateTime.now()).toString();
    List<RiskData> chartData = [];

    String time = '0';

    for (int i = 0; i < fullRiskData.length; i++) {
      if (dateNow == fullRiskData[i]["Date"].toString()) {
        if (fullRiskData[i]["Time"].substring(0, 2) != time) {
          time = fullRiskData[i]["Time"].substring(0, 2);
          chartData.add(RiskData(fullRiskData[i]["Blk 8"], int.parse(time)));
        }
      }
    }

    return chartData;
  }
}

getRisk(risk) {
  String risktext = 'Low Risk';
  if (risk == null) {
    risktext = "Loading...";
  }

  if (risk != null) {
    if ((risk >= 1) && (risk <= 3)) {
      risktext = 'Low Risk';
    } else if ((risk >= 4) && (risk <= 7)) {
      risktext = 'Medium Risk';
    } else if ((risk >= 8) && (risk <= 10)) {
      risktext = 'High Risk';
    }
  }

  return risktext;
}

class RiskData {
  RiskData(this.risks, this.time);
  final int risks;
  final int time;
}
