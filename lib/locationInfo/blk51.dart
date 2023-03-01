// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rerac_113/screens/home.dart';
import 'package:rerac_113/screens/markerInfo.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:rerac_113/widgets/globals.dart';

class Blk51 extends StatefulWidget {
  const Blk51({super.key});

  @override
  State<Blk51> createState() => Blk51State();
}

class Blk51State extends State<Blk51> {
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
    int blk51Risk = risk["Blk 51"];

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
                    "Location: Block 51",
                    style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0), fontSize: 30),
                  ),
                  Text("Current risk: " + getRisk(blk51Risk)),
                  Text("Average risk for the day: " +
                      AverageRisk['Blk 51'].toString()),
                  SfCartesianChart(
                    title: ChartTitle(text: 'Hourly risk analysis'),
                    legend: Legend(isVisible: true),
                    tooltipBehavior: _tooltipBehavior,
                    series: <ChartSeries>[
                      LineSeries<RiskData, int>(
                          name: 'Risk Number',
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
                    children: [
                      Image.asset(
                        'assets/blk51_1.jpg',
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
            color: (blk51Risk >= 1 && blk51Risk <= 3)
                ? Colors.green
                : (blk51Risk >= 4 && blk51Risk <= 7)
                    ? Colors.orange
                    : (blk51Risk >= 8 && blk51Risk <= 10)
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
                    "Block 51",
                    style: TextStyle(color: Colors.white, fontSize: 30),
                  ),
                ),
              ),
              SizedBox(
                width: 142.5,
                child: Center(
                  child: Text(
                    getRisk(blk51Risk),
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
    String dateNow = DateFormat("yyyy-MM-dd").format(DateTime.now()).toString();
    List<RiskData> chartData = [];

    String time = '0';

    for (int i = 0; i < fullRiskData.length; i++) {
      if (dateNow == fullRiskData[i]["Date"].toString()) {
        if (fullRiskData[i]["Time"].substring(0, 2) != time) {
          time = fullRiskData[i]["Time"].substring(0, 2);
          chartData.add(RiskData(fullRiskData[i]["Blk 51"], int.parse(time)));
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
