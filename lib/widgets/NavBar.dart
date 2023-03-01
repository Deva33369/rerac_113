import 'package:flutter/material.dart';
import 'package:open_settings/open_settings.dart';
import 'package:rerac_113/screens/loginPage.dart';
import 'package:rerac_113/widgets/globals.dart' as globals;

class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Remove padding
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              'Profile',
              style: TextStyle(fontSize: 30),
            ),
            accountEmail:
                Text(globals.globalString), //to show the user's email id
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => OpenSettings.openAppSetting(),
          ),
          ListTile(
            leading: const Icon(Icons.location_searching),
            title: const Text('Locations Settings'),
            onTap: () => OpenSettings.openLocationSourceSetting(),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () => OpenSettings.openNotificationSetting(),
          ),
          const Divider(), //to draw a line at the bottom for aesthetic purposes
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.exit_to_app),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => LoginPage())),
          ),
        ],
      ),
    );
  }
}
