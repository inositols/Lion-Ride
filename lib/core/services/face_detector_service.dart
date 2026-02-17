import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  FaceDetector? _faceDetector;
  bool _isDisposed = false;

  FaceDetectorService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableTracking: true,
        enableContours: true,
        enableLandmarks: false,
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
  }

  Future<List<Face>> detectFaces(InputImage inputImage) async {
    // Immediate escape if we are shutting down
    if (_isDisposed || _faceDetector == null) return [];

    try {
      return await _faceDetector!.processImage(inputImage);
    } catch (e) {
      // Catching the JNI detach or instance-already-closed errors
      return [];
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    final detector = _faceDetector;
    _faceDetector = null; // Sever the link immediately

    try {
      await detector?.close();
    } catch (e) {
      // Suppress disposal errors during JNI shutdown
    }
  }
}
