// ignore_for_file: depend_on_referenced_packages, file_names

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:rerac_113/map_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:rerac_113/screens/home.dart';
import 'package:email_validator/email_validator.dart';
import 'package:rerac_113/widgets/NavBar.dart';
import 'package:rerac_113/widgets/globals.dart' as globals;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  List<dynamic> userData =
      []; //Initializes an empty list to store user data retrieved from the database.
  TextEditingController nameController = TextEditingController();
  //Creates a text editing controller for the email input field.
  TextEditingController passwordController = TextEditingController();
  //Creates a text editing controller for the password input field.

  //Returns a boolean value indicating whether the email address is valid or not.
  validateEmail(String email) {
    return EmailValidator.validate(email);
  }

  validatePassword(String email, String password) {
    bool isvalid = EmailValidator.validate(email);

    // loops through the userData list to check if the email and password match a user's credentials in the database.
    //Returns a boolean value indicating whether the password is valid or not.
    for (var element in userData) {
      if (email == element["Email"] && password == element["Password"]) {
        isvalid = true;
        break;
      } else {
        isvalid = false;
      }
    }

    return isvalid;
  }

  var text = '';

  @override
  Widget build(BuildContext context) {
    getUsers();
    //The rebuild function takes an Element as input and marks it as needing to be rebuilt.
    // It then recursively visits all its children and calls the rebuild function on each of them.
    void rebuildAllChildren(BuildContext context) {
      void rebuild(Element el) {
        el.markNeedsBuild();
        el.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    }

    //Once the widget tree is rebuilt, any changes that were made to the state or the UI will be reflected on the screen.
    rebuildAllChildren(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Login Page",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: 400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                      child: Container(
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/icon.png'), //rerac image
                            fit: BoxFit.fill)),
                  ))
                ],
              ),
            ),
            Padding(
              //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
              padding: const EdgeInsets.symmetric(horizontal: 15),

              child: TextField(
                controller: nameController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    labelText: 'Email',
                    errorText:
                        _errorText, //error text message if the email id format is invalid
                    hintText: 'Enter valid email id as abc@gmail.com'),
                onChanged: (text) => setState(() => text),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextField(
                obscureText: true,
                controller: passwordController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    labelText: 'Password',
                    errorText: _errorText2,
                    hintText: 'Enter secure password'),
                onChanged: (text) => setState(() => text),
              ),
            ),
            TextButton(
              onPressed: () async {
                MapUtils
                    .openWebsiteFP(); //opens the forgot password page of the website
              },
              child: const Text(
                'Forgot Password',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: TextButton(
                onPressed: () {
                  getUsers(); //gets the info from the user's database
                  setState(() {
                    globals.globalString =
                        nameController.text; //stores in the user's email id
                  });
                  if (_errorText == null && _errorText2 == null) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Home()));
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(
                          content: Text('Wrong password or email id'),
                        );
                      },
                    );
                  }
                },
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.black, fontSize: 25),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextButton(
              onPressed: () async {
                MapUtils.openWebsite();
              },
              child: const Text(
                'New User? Create a new account',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String localhost() {
    if (Platform.isAndroid) {
      return globals.IPaddress;
    } else {
      return '172.16.21.126:3000';
    }
  }

  // This function sends a GET request to the server to fetch all users' data from the specified database.
  // The response is parsed as a JSON object and stored in the `userData` state variable.
  getUsers() async {
    // Define query parameters for the GET request
    final queryParameters = {'request': 'ALL', 'database': 'users'};
    // Construct the URL for the GET request
    final url = Uri.http(localhost(), '/get', queryParameters);
    // Send the GET request and wait for the response
    Response response = await get(url);
    // Update the `userData` state variable with the fetched data and print it to the console
    setState(() {
      userData = jsonDecode(response.body);
      print(userData);
    });
  }

  String? get _errorText {
    // at any time, we can get the text from _controller.value.text
    final email = nameController.value.text;
    // Move this logic this outside the widget for more testable code
    if (validateEmail(nameController.text) == false) {
      return 'enter a valid email address';
    }
    // return null if the text is valid
    return null;
  }

  String? get _errorText2 {
    // at any time, we can get the text from _controller.value.text
    final email = nameController.value.text;
    final password = passwordController.value.text;
    // Move this logic this outside the widget for more testable code
    if (password.length < 8) {
      return 'Password is too short. It should be more than 8 characters';
    }
    if (!validatePassword(email, password)) {
      return 'Either email or password is wrong.';
    }
    // return null if the text is valid
    return null;
  }
}
