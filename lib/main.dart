// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'models/models.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> permissionHandler(Permission permission, String name) async {
  var status = await permission.request();

  if (status.isGranted) {
    Fluttertoast.showToast(msg: '$name permission granted');
  } else if (status.isPermanentlyDenied) {
    Fluttertoast.showToast(
      msg: '$name permission permanently denied. Enable it in settings',
    );
    openAppSettings();
  } else if (status.isRestricted) {
    Fluttertoast.showToast(msg: '$name permission restricted by system');
  } else if (status.isLimited) {
    Fluttertoast.showToast(msg: '$name permission limited access granted');
  } else if (status.isDenied) {
    Fluttertoast.showToast(msg: '$name permission denied');
  } else {
    Fluttertoast.showToast(msg: '$name error');
  }
}

Future<void> requestPermissions() async {
  await [Permission.camera, Permission.location, Permission.sms].request();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(PhotoModelAdapter());

  await Hive.openBox<UserModel>('users');
  await Hive.openBox<PhotoModel>('photos');
  await Hive.openBox('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Hive.box('settings');
    final currentUserId = settings.get('currentUserId') as String?;

    return MaterialApp(
      title: 'GeoUnião',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: currentUserId == null
          ? const AuthScreen()
          : FutureBuilder(
              future: availableCameras(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final cameras = snapshot.data as List<CameraDescription>;
                  return HomeScreen(camera: cameras.first);
                } else {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
    );
  }
}
