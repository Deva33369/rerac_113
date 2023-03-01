// ignore_for_file: depend_on_referenced_packages, file_names, library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:rerac_113/screens/home.dart';
import 'package:rerac_113/widgets/globals.dart';

class BusStop extends StatefulWidget {
  const BusStop({super.key});

  @override
  _BusStopExample createState() => _BusStopExample();
}

class _BusStopExample extends State<BusStop> {
  List<dynamic> busData = [];

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  _getBus() async {
    final queryParameters = {'request': 'ALL', 'database': 'bus_arrival'};
    final url = Uri.http(_localhost(), '/get', queryParameters);
    Response response = await get(url);
    setState(() {
      busData = jsonDecode(response.body);
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
  Widget build(BuildContext context) {
    _getBus();
    rebuildAllChildren(context);

    List<int> serviceNo = [];
    List<List> arrivalTime = [];
    List<List> serviceArrivalTime = [];

    for (int i = 0; i < busData.length; i++) {
      serviceNo.add(busData[i]["ServiceNo"]);
      List arrival_time = busData[i]["ArrivalTime"]
          .replaceAll("[", "")
          .replaceAll("]", "")
          .split(",");
      arrivalTime.add(arrival_time);
    }

    for (int i = 0; i < serviceNo.length; i++) {
      List individualBusTiming = [];
      individualBusTiming.add(serviceNo[i]);
      for (int j = 0; j < arrivalTime[i].length; j++) {
        individualBusTiming.add(arrivalTime[i][j]);
      }
      serviceArrivalTime.add(individualBusTiming);
    }

    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Home()),
                    );
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                ),
                const Text(
                  'Ngee Ann Poly Bus Stop',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
          body: ListView(scrollDirection: Axis.horizontal, children: <Widget>[
            DataTable(
              columns: const [
                DataColumn(
                    label: Text('Bus Number',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('        1',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('        2',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ))),
                DataColumn(
                    label: Text('        3',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
              ],
              rows: serviceArrivalTime
                  .map(
                    (times) => DataRow(cells: [
                      DataCell(
                        Text("          ${times[0].toString()}",
                            textAlign: TextAlign.center),
                      ),
                      DataCell(
                        Text("          ${times[1].toString()}",
                            textAlign: TextAlign.center),
                      ),
                      DataCell(
                        Text("          ${times[2].toString()}",
                            textAlign: TextAlign.center),
                      ),
                      DataCell(
                        Text("          ${times[3].toString()}",
                            textAlign: TextAlign.center),
                      ),
                    ]),
                  )
                  .toList(),
            ),
          ])),
    );
  }
}
