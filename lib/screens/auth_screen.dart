// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/models.dart';
import 'home_screen.dart';
import 'package:camera/camera.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Box<UserModel> get usersBox => Hive.box<UserModel>('users');
  Box get settingsBox => Hive.box('settings');

  String _hashPassword(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha usuário e senha')));
      return;
    }

    final exists = usersBox.values.any((u) => u.username == username);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário já existe')));
      return;
    }

    final id = const Uuid().v4();
    final hash = _hashPassword(password);
    final user = UserModel(id: id, username: username, passwordHash: hash);
    await usersBox.put(id, user);

    settingsBox.put('currentUserId', id);

    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(camera: cameras.first)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(camera: CameraDescription(name: 'none', lensDirection: CameraLensDirection.back, sensorOrientation: 0))));
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha usuário e senha')));
      return;
    }

    final hash = _hashPassword(password);

    UserModel? entry;
    try {
      entry = usersBox.values.firstWhere((u) => u.username == username && u.passwordHash == hash);
    } catch (e) {
      entry = null;
    }

    if (entry == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário ou senha inválidos')));
      return;
    }

    settingsBox.put('currentUserId', entry.id);

    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(camera: cameras.first)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(camera: CameraDescription(name: 'none', lensDirection: CameraLensDirection.back, sensorOrientation: 0))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo_geo_uniao.png', height: 130),
              const SizedBox(height: 16),
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Usuário')),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: _login, child: const Text('Entrar'))),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton(onPressed: _register, child: const Text('Cadastrar'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}