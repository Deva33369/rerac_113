import 'package:flutter/material.dart';
import 'package:rerac_113/screens/home.dart';
import 'package:email_validator/email_validator.dart';

class MainPage extends StatefulWidget {
  LoginPage createState() => LoginPage();
}

class LoginPage extends State<MainPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Validate(String email) {
    bool isvalid = EmailValidator.validate(email);
    print(isvalid);
    return isvalid;
  }

  var text = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Login Page"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Center(
                child: Container(
                  width: 200,
                  height: 150,
                  /*decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50.0)),*/
                ),
              ),
            ),
            Padding(
              //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
              padding: EdgeInsets.symmetric(horizontal: 15),

              child: TextField(
                controller: nameController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    errorText: _errorText,
                    hintText: 'Enter valid email id as abc@gmail.com'),
                onChanged: (text) => setState(() => text),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              //padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                obscureText: true,
                controller: passwordController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    errorText: _errorText2,
                    hintText: 'Enter secure password'),
                onChanged: (text) => setState(() => text),
              ),
            ),
            TextButton(
              onPressed: () {
                //TODO FORGOT PASSWORD SCREEN GOES HERE
              },
              child: Text(
                'Forgot Password',
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(20)),
              child: TextButton(
                onPressed: () {
                  if (_errorText == null && _errorText2 == null) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Home()));
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          // Retrieve the text the that user has entered by using the
                          // TextEditingController.
                          content: Text('Wrong password or email id'),
                        );
                      },
                    );
                  }
                  // Validate(nameController.text);
                  // if(Validate(nameController.text)== false){

                  // }
                  // if ((nameController.text.toString() ==
                  //         'kumar.devadharshini@gmail.com') &&
                  //     (passwordController.text.toString() == 'hello')) {
                  //   Navigator.push(context,
                  //       MaterialPageRoute(builder: (context) => Home()));
                  // } else {
                  //   showDialog(
                  //     context: context,
                  //     builder: (context) {
                  //       return AlertDialog(
                  //         // Retrieve the text the that user has entered by using the
                  //         // TextEditingController.
                  //         content: Text('Wrong password or email id'),
                  //       );
                  //     },
                  //   );
                  // }
                },
                child: Text(
                  'Login',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
            SizedBox(
              height: 130,
            ),
            Text('New User? Create Account')
          ],
        ),
      ),
    );
  }

  String? get _errorText {
    // at any time, we can get the text from _controller.value.text
    final text = nameController.value.text;
    // Note: you can do your own custom validation here
    // Move this logic this outside the widget for more testable code
    if (text.isEmpty) {
      return 'Can\'t be empty';
    }
    if (Validate(nameController.text) == false) {
      return 'enter a valid email address';
    }
    // return null if the text is valid
    return null;
  }

  String? get _errorText2 {
    // at any time, we can get the text from _controller.value.text
    final text = passwordController.value.text;
    // Note: you can do your own custom validation here
    // Move this logic this outside the widget for more testable code
    if (text.isEmpty) {
      return 'Can\'t be empty';
    }
    if (text.length < 8) {
      return 'Password is too short. It should be more than 8 characters';
    }
    // return null if the text is valid
    return null;
  }
}
