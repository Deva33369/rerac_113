import 'package:flutter/material.dart';
import 'package:open_settings/open_settings.dart';
import 'package:rerac_113/screens/loginPage.dart';

class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Remove padding
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Oflutter.com'),
            accountEmail: const Text('example@gmail.com'),
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: Image.network(
                  'https://oflutter.com/wp-content/uploads/2021/02/girl-profile.png',
                  fit: BoxFit.cover,
                  width: 90,
                  height: 90,
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
              image: DecorationImage(
                  fit: BoxFit.fill,
                  image: NetworkImage(
                      'https://oflutter.com/wp-content/uploads/2021/02/profile-bg3.jpg')),
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
            leading: const Icon(Icons.location_searching),
            title: const Text('Notifications'),
            onTap: () => OpenSettings.openNotificationSetting(),
          ),
          ListTile(
            leading: const Icon(Icons.location_searching),
            title: const Text('Night Display'),
            onTap: () => OpenSettings.openNightDisplaySetting(),
          ),
          const Divider(),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.exit_to_app),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => MainPage())),
          ),
        ],
      ),
    );
  }
}
