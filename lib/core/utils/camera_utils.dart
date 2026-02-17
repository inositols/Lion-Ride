import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraUtils {
  static InputImage? inputImageFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
    DeviceOrientation? deviceOrientation,
  }) {
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      if (deviceOrientation == null) {
        // Fallback to sensor orientation if device orientation is unknown
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else {
        var rotationCompensation = _orientations[deviceOrientation]!;
        if (camera.lensDirection == CameraLensDirection.front) {
          // Front-facing camera
          rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
        } else {
          // Back-facing camera
          rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    // IOS Handling: BGRA8888
    if (Platform.isIOS) {
      if (image.format.raw != InputImageFormat.bgra8888.rawValue) return null;
      return InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    // ANDROID Handling: YUV_420_888 -> NV21
    if (Platform.isAndroid) {
      // ML Kit on Android expects NV21 (Format 17) for `fromBytes`.
      // The Camera plugin gives us YUV_420_888. We must convert it manually.
      if (image.format.group != ImageFormatGroup.yuv420) return null;

      final bytes = _yuv420ToNv21(image);

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21, // Force NV21
          bytesPerRow: image.width, // In NV21, bytes per row = width
        ),
      );
    }

    return null;
  }

  // Helper to concatenate planes (Only for iOS BGRA)
  static Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  // CRITICAL: Convert YUV420 (3 planes) to NV21 (ByteArray)
  static Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final Uint8List yBuffer = yPlane.bytes;
    final Uint8List uBuffer = uPlane.bytes;
    final Uint8List vBuffer = vPlane.bytes;

    final int numPixels = (width * height * 1.5).toInt();
    final Uint8List nv21 = Uint8List(numPixels);

    // 1. Copy Y Plane (Luminance)
    int idY = 0;
    int idUV = width * height;
    final int uvWidth = width ~/ 2;
    final int uvHeight = height ~/ 2;

    // Optimization: If stride == width, copy entire Y buffer at once
    if (yPlane.bytesPerRow == width) {
      nv21.setRange(0, width * height, yBuffer);
      idY = width * height;
    } else {
      for (int y = 0; y < height; y++) {
        final int yOffset = y * yPlane.bytesPerRow;
        for (int x = 0; x < width; x++) {
          nv21[idY++] = yBuffer[yOffset + x];
        }
      }
    }

    // 2. Interleave U and V (Chrominance) -> NV21 is VU order
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < uvHeight; y++) {
      final int uvOffset = y * uvRowStride;
      for (int x = 0; x < uvWidth; x++) {
        // V byte
        nv21[idUV++] = vBuffer[uvOffset + (x * uvPixelStride)];
        // U byte
        nv21[idUV++] = uBuffer[uvOffset + (x * uvPixelStride)];
      }
    }

    return nv21;
  }

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
}
