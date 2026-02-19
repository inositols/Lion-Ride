import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/verification/verification_bloc.dart';
import '../../core/utils/camera_utils.dart';
import '../../core/services/face_detector_service.dart';

class FaceLivenessScreen extends StatefulWidget {
  const FaceLivenessScreen({super.key});

  @override
  State<FaceLivenessScreen> createState() => _FaceLivenessScreenState();
}

class _FaceLivenessScreenState extends State<FaceLivenessScreen> {
  CameraController? _cameraController;
  final FaceDetectorService _faceService = FaceDetectorService();
  List<CameraDescription> _availableCameras = [];
  int _cameraIndex = 0;

  bool _isBusy = false; 
  bool _isDisposed = false; 
  DateTime? _lastRun; 

  String _hintText = "Center your face...";
  bool _hasSmiled = false;
  bool _faceDetected = false;

  List<Face> _faces = [];
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _findAndInitCamera();
  }

  Future<void> _findAndInitCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) return;

      // Default to front camera
      _cameraIndex = _availableCameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front
      );
      if (_cameraIndex == -1) _cameraIndex = 0;

      await _initializeCamera(_availableCameras[_cameraIndex]);
    } catch (e) {
      debugPrint("Camera List Error: $e");
    }
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      _cameraController = controller;
      await controller.initialize();

      if (_isDisposed || !mounted) return;

      controller.startImageStream((image) {
        _processCameraImage(image, camera);
      });

      setState(() {});
    } catch (e) {
      debugPrint("Camera Init Error: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras.length < 2) return;
    
    await _stopCamera(permanent: false);
    _cameraIndex = (_cameraIndex + 1) % _availableCameras.length;
    _isDisposed = false; // Unlock for re-init
    await _initializeCamera(_availableCameras[_cameraIndex]);
  }

  void _processCameraImage(CameraImage image, CameraDescription camera) async {
    final now = DateTime.now();
    if (_lastRun != null && now.difference(_lastRun!).inMilliseconds < 500) return;

    if (_isDisposed || !mounted || _hasSmiled || _isBusy) return;
    _isBusy = true;
    _lastRun = now;

    try {
      final inputImage = CameraUtils.inputImageFromCameraImage(
        image: image,
        camera: camera,
        deviceOrientation: _cameraController?.value.deviceOrientation,
      );

      if (inputImage == null) {
        debugPrint("CameraUtils: InputImage is null");
        _isBusy = false;
        return;
      }

      final faces = await _faceService.detectFaces(inputImage);
      debugPrint("FaceDetector: Detected ${faces.length} faces");

      if (_isDisposed || !mounted || _hasSmiled) {
        _isBusy = false;
        return;
      }

      setState(() {
        _faces = faces;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());

        if (faces.isEmpty) {
          _faceDetected = false;
          if (!_hasSmiled) _hintText = _isBusy ? "Analyzing..." : "Center your face...";
        } else {
          _faceDetected = true;
          final face = faces.first;

          if (face.smilingProbability != null && face.smilingProbability! > 0.6) {
            _hasSmiled = true;
            _hintText = "Liveness Verified!";
            _onSuccess();
          } else {
            _hintText = "Great! Now SMILE to verify";
          }
        }
      });
    } catch (e) {
      debugPrint("Detection Error: $e");
    } finally {
      if (!_isDisposed) _isBusy = false;
    }
  }

  Future<void> _onSuccess() async {
    await _stopCamera();
    if (mounted) {
      context.read<VerificationBloc>().add(FaceVerifiedSuccess());
    }
  }

  Future<void> _stopCamera({bool permanent = true}) async {
    _isDisposed = permanent;
    if (permanent) _faceService.dispose();

    final controller = _cameraController;
    _cameraController = null;

    if (controller != null) {
      if (controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
        } catch (e) {
          debugPrint("Error stopping stream: $e");
        }
      }
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    if (!_isDisposed) _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isDisposed) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    final isFront = _cameraController!.description.lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Feed with Mirroring for Front Camera
          Center(
            child: AspectRatio(
              aspectRatio: 1 / _cameraController!.value.aspectRatio,
              child: Stack(
                children: [
                   // Mirror the preview only for front camera
                  Transform(
                    alignment: Alignment.center,
                    transform: isFront ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
                    child: CameraPreview(_cameraController!),
                  ),
                  
                  // 2. FACE MESH (Contours & Lines)
                  if (_faces.isNotEmpty && _imageSize != null)
                    CustomPaint(
                      painter: FacePainter(
                        faces: _faces, 
                        imageSize: _imageSize!,
                        isMirrored: isFront,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Scanner UI Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.8), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.transparent)),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 60),
                    width: 260,
                    height: 360,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(130),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Action Buttons (Top)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 30),
              onPressed: _toggleCamera,
            ),
          ),

          // 5. Instructions Card
          Positioned(
            bottom: 80,
            left: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00382E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasSmiled ? Colors.greenAccent : Colors.white12,
                  width: 2,
                ),
              ),
              child: Text(
                _hintText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final bool isMirrored;

  FacePainter({required this.faces, required this.imageSize, required this.isMirrored});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageSize.height;
    final double scaleY = size.height / imageSize.width;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.greenAccent.withValues(alpha: 0.8);

    for (final face in faces) {
      Offset mapPoint(math.Point<int> point) {
        double x = point.x.toDouble() * scaleX;
        double y = point.y.toDouble() * scaleY;
        
        // If mirrored (front camera), flip the X coordinate
        if (isMirrored) {
          x = size.width - x;
        }
        return Offset(x, y);
      }

      for (final type in FaceContourType.values) {
        final contour = face.contours[type];
        if (contour != null && contour.points.isNotEmpty) {
          final path = Path();
          final points = contour.points;
          path.moveTo(mapPoint(points[0]).dx, mapPoint(points[0]).dy);
          for (var i = 1; i < points.length; i++) {
            path.lineTo(mapPoint(points[i]).dx, mapPoint(points[i]).dy);
          }
          if (type == FaceContourType.face || type == FaceContourType.leftEye || type == FaceContourType.rightEye) {
            path.close();
          }
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) => true;
}
