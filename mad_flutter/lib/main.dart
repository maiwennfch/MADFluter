import 'package:flutter/material.dart';
import 'package:mad_flutter/screens/first.dart';
import 'package:mad_flutter/screens/map.dart';
import 'package:mad_flutter/screens/second.dart';
import 'package:mad_flutter/screens/settings_screen.dart';
import 'package:mad_flutter/widgets/navigation_rails.dart';
import 'package:mad_flutter/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MAD helloworld',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data != null) {
              return FirstScreen(); // User is logged
              }
            // return const LoginScreen(); // User isn't logged
            return NavRailMenu();
            }
          return const CircularProgressIndicator(); // Waiting for connection
          },
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
    );
     /*
    return MaterialApp(
      title: 'Flutter MAD helloworld',
      debugShowCheckedModeBanner: false,
      home: NavRailMenu(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),

    );
    */
  }
}


class NavRailMenu extends StatefulWidget {
  const NavRailMenu({super.key});

  @override
  _NavRailMenuState createState() => _NavRailMenuState();
}

class _NavRailMenuState extends State<NavRailMenu> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    FirstScreen(),
    const SecondScreen(),
    const SettingsScreen(),
    const MapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade200,
        title: const Text('Mad Flutter App'),
      ),
      body: Row(
        children: <Widget>[
          NavigationRailWidget(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
    );
  }
}
