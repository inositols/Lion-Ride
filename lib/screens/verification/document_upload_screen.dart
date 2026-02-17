import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../logic/verification/verification_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../models/user_model.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _ninFile;
  File? _bikeFile;
  bool _isUploadingNin = false;
  bool _isUploadingBike = false;

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (image != null) {
      setState(() {
        if (type == 'nin') {
          _ninFile = File(image.path);
          _isUploadingNin = true;
        } else {
          _bikeFile = File(image.path);
          _isUploadingBike = true;
        }
      });
      
      if (!mounted) return;
      context.read<VerificationBloc>().add(UploadDocRequested(image.path, type));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listener: (context, state) {
        if (state is VerificationStep3Docs) {
          setState(() {
            _isUploadingNin = false;
            _isUploadingBike = false;
          });
        } else if (state is VerificationFailure) {
          setState(() {
            _isUploadingNin = false;
            _isUploadingBike = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${state.error}'), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            UserModel? user;
            if (authState is AuthAuthenticated) {
              user = authState.user;
            }

            final hasNin = _ninFile != null || (user?.ninUrl != null);
            final hasBike = _bikeFile != null || (user?.bikePapersUrl != null);
            final canContinue = hasNin && hasBike && !_isUploadingNin && !_isUploadingBike;

            return Scaffold(
              backgroundColor: const Color(0xFF00382E),
              appBar: AppBar(
                title: Text('Identity Verification', style: GoogleFonts.outfit()),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Upload Documents',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide clear photos of your official documents.',
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    _buildDocCard(
                      title: 'NIN / Voters Card',
                      file: _ninFile,
                      remoteUrl: user?.ninUrl,
                      isUploading: _isUploadingNin,
                      onTap: () => _isUploadingNin ? null : _pickImage('nin'),
                    ),
                    const SizedBox(height: 20),
                    _buildDocCard(
                      title: 'Bike Papers',
                      file: _bikeFile,
                      remoteUrl: user?.bikePapersUrl,
                      isUploading: _isUploadingBike,
                      onTap: () => _isUploadingBike ? null : _pickImage('bike_papers'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: canContinue
                          ? () {
                              context.read<VerificationBloc>().add(DocumentStepCompleted());
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF004D40),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('CONTINUE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocCard({
    required String title,
    File? file,
    String? remoteUrl,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              )
            else if (remoteUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  remoteUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
                  ),
                ),
              ),
            if (file == null && remoteUrl == null && !isUploading)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Colors.white60, size: 40),
                  const SizedBox(height: 12),
                  Text(title, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500)),
                ],
              ),
            if (isUploading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            if ((file != null || remoteUrl != null) && !isUploading)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
