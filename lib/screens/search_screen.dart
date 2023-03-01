// ignore_for_file: prefer_const_constructors, avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rerac_113/map_utils.dart';
import 'package:rerac_113/screens/map_screen.dart';
import 'package:google_place/google_place.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:geolocator/geolocator.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _startSearchFieldController =
      TextEditingController(); //search field for origin
  final _endSearchFieldController =
      TextEditingController(); //search field for destination

  //These lines define two nullable variables of type DetailsResult which will hold the start and end positions of a route.
  DetailsResult? startPosition;
  DetailsResult? endPosition;

  //These lines define two late-initialized variables of type FocusNode which are used to manage focus for the text fields used to input the start and end addresses.
  late FocusNode startFocusNode;
  late FocusNode endFocusNode;

  late GooglePlace googlePlace;
  //This line defines a late-initialized variable of type GooglePlace which is used to interact with the Google Places API.
  List<AutocompletePrediction> predictions = [];
  // is used to debounce user input before sending requests to the Google Places API. A debounce timer helps to prevent excessive
  //API requests by delaying the request until the user has finished typing.
  Timer? _debounce;
  String? _currentAddress;
  Position? _currentPosition;

  Future<void> _getCurrentPosition() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String apiKey = 'AIzaSyCsqrq6bn25yMgMQILghZZ3bVcb29V5ubA';
    googlePlace = GooglePlace(apiKey);

    startFocusNode = FocusNode();
    endFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    startFocusNode.dispose();
    endFocusNode.dispose();
  }

  void autoCompleteSearch(String value) async {
    // // Calls the Google Places API to get autocomplete predictions for the input value
    var result = await googlePlace.autocomplete.get(value);
    // Checks if the result is not null and contains at least one prediction and the widget is still mounted
    if (result != null && result.predictions != null && mounted) {
      //// Prints the description of the first prediction returned by the API
      print(result.predictions!.first.description);
      // // Sets the state of the widget to update the list of predictions displayed to the user
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _startSearchFieldController,
              autofocus: false,
              focusNode: startFocusNode,
              style: TextStyle(fontSize: 18),
              decoration: InputDecoration(
                  hintText: 'Starting Point',
                  hintStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 18),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: InputBorder.none,
                  suffixIcon: _startSearchFieldController.text.isNotEmpty ||
                          _startSearchFieldController
                              .text.isEmpty //for origin search
                      ? IconButton(
                          //when pressed gives back the user the current location to set it as the origin
                          onPressed: () {
                            String address = _currentAddress.toString();
                            _getCurrentPosition();
                            setState(() {
                              predictions = [];
                              _startSearchFieldController.clear();
                              if (_startSearchFieldController == null) {
                                _startSearchFieldController.text = "loading..";
                              } else {
                                _startSearchFieldController.text =
                                    address.toString();
                              }
                            });
                          },
                          icon: Icon(Icons.my_location),
                        )
                      : null),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 1000), () {
                  if (value.isNotEmpty) {
                    //places api
                    autoCompleteSearch(value);
                  } else {
                    //clear out the results
                    setState(() {
                      predictions = [];
                      startPosition = null;
                    });
                  }
                });
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: _endSearchFieldController,
              autofocus: false,
              focusNode: endFocusNode,
              enabled: _startSearchFieldController.text.isNotEmpty &&
                  startPosition != null,
              style: TextStyle(fontSize: 18),
              decoration: InputDecoration(
                  hintText: 'End Point',
                  hintStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 18),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: InputBorder.none,
                  suffixIcon: _endSearchFieldController.text.isEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              predictions = [];
                              _endSearchFieldController.clear();
                            });
                          },
                          icon: Icon(Icons.clear_outlined),
                        )
                      : null),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 1000), () {
                  if (value.isNotEmpty) {
                    //places api
                    autoCompleteSearch(value);
                  } else {
                    //clear out the results
                    setState(() {
                      predictions = [];
                      endPosition = null;
                    });
                  }
                });
              },
            ),
            ListView.builder(
                shrinkWrap: true,
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        Icons.pin_drop,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      predictions[index].description.toString(),
                    ),
                    onTap: () async {
                      final placeId = predictions[index].placeId!;
                      final details = await googlePlace.details.get(placeId);
                      if (details != null &&
                          details.result != null &&
                          mounted) {
                        if (startFocusNode.hasFocus) {
                          setState(() {
                            startPosition = details.result;
                            _startSearchFieldController.text =
                                details.result!.name!;
                            predictions = [];
                          });
                        } else {
                          setState(() {
                            endPosition = details.result;
                            _endSearchFieldController.text =
                                details.result!.name!;
                            predictions = [];
                          });
                        }

                        if (startPosition != null && endPosition != null) {
                          print('navigate');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreen(
                                  startPosition: startPosition,
                                  endPosition: endPosition),
                            ),
                          );
                        }
                      }
                    },
                  );
                })
          ],
        ),
      ),
    );
  }
}
