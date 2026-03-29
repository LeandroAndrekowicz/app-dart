import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CameraFullScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraFullScreen({super.key, required this.camera});

  @override
  State<CameraFullScreen> createState() => _CameraFullScreenState();
}

class _CameraFullScreenState extends State<CameraFullScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  late CameraDescription _currentCamera;

  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  DateTime _lastZoomUpdate = DateTime.now();

  final double zoomSensitivity = 0.5; 

  @override
  void initState() {
    super.initState();
    _currentCamera = widget.camera;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();

    await _initializeControllerFuture;

    _minZoom = await _controller.getMinZoomLevel();
    _maxZoom = await _controller.getMaxZoomLevel();
    _currentZoom = _minZoom;

    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
    final cameras = await availableCameras();

    final newCamera = cameras.firstWhere(
      (camera) => camera.lensDirection != _currentCamera.lensDirection,
    );

    await _controller.dispose();

    _currentCamera = newCamera;

    await _initializeCamera();
  }

  Future<void> _takePictureAndReturn() async {
    try {
      await _initializeControllerFuture;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final image = await _controller.takePicture();

      if (!mounted) return;

      Navigator.of(context).pop({
        'image': image,
        'position': position,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final size = MediaQuery.of(context).size;
                final deviceRatio = size.width / size.height;

                final previewSize = _controller.value.previewSize!;
                final previewRatio =
                    previewSize.height / previewSize.width;

                final scale = deviceRatio / previewRatio;

                return Transform.scale(
                  scale: scale < 1 ? 1 / scale : scale,
                  alignment: Alignment.center,
                  child: Center(
                    child: GestureDetector(
                      onScaleStart: (details) {
                        _baseZoom = _currentZoom;
                      },
                      onScaleUpdate: (details) {
                        final now = DateTime.now();

                        if (now.difference(_lastZoomUpdate).inMilliseconds < 30) {
                          return;
                        }

                        double scaleFactor =
                            1 + ((details.scale - 1) * zoomSensitivity);

                        double zoom = _baseZoom * scaleFactor;
                        zoom = zoom.clamp(_minZoom, _maxZoom);

                        _controller.setZoomLevel(zoom);

                        _currentZoom = zoom;
                        _lastZoomUpdate = now;
                      },
                      child: CameraPreview(_controller),
                    ),
                  ),
                );
              },
            ),

            Positioned(
              top: 16 + MediaQuery.of(context).padding.top,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),

            Positioned(
              top: 16 + MediaQuery.of(context).padding.top,
              right: 12,
              child: IconButton(
                icon: const Icon(
                  Icons.cameraswitch,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: _switchCamera,
              ),
            ),

            Positioned(
              bottom: 28 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePictureAndReturn,
                  child: Container(
                    height: 78,
                    width: 78,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Container(
                        height: 54,
                        width: 54,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}