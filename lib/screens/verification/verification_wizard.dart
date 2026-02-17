import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../logic/verification/verification_bloc.dart';
import 'phone_verification_screen.dart';
import 'face_liveness_screen.dart';
import 'document_upload_screen.dart';
import 'guarantor_form_screen.dart';

class VerificationWizard extends StatefulWidget {
  const VerificationWizard({super.key});

  @override
  State<VerificationWizard> createState() => _VerificationWizardState();
}

class _VerificationWizardState extends State<VerificationWizard> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialState = context.read<VerificationBloc>().state;
    int initialPage = 0;
    if (initialState is VerificationStep2Face) initialPage = 1;
    if (initialState is VerificationStep3Docs) initialPage = 2;
    if (initialState is VerificationStep4Guarantor) initialPage = 3;
    if (initialState is VerificationPendingApproval) initialPage = 4;
    
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerificationBloc, VerificationState>(
      listener: (context, state) {
        int? targetPage;
        if (state is VerificationStep1Phone || state is VerificationOtpSent) {
          targetPage = 0;
        } else if (state is VerificationStep2Face) {
          targetPage = 1;
        } else if (state is VerificationStep3Docs) {
          targetPage = 2;
        } else if (state is VerificationStep4Guarantor) {
          targetPage = 3;
        } else if (state is VerificationPendingApproval) {
          targetPage = 4;
        }

        if (targetPage != null && _pageController.hasClients && _pageController.page?.round() != targetPage) {
          _pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      },
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const PhoneVerificationScreen(),
          const FaceLivenessScreen(),
          const DocumentUploadScreen(),
          const GuarantorFormScreen(),
          _buildPendingUI(),
        ],
      ),
    );
  }

  Widget _buildPendingUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF00382E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, color: Colors.yellowAccent, size: 80),
              const SizedBox(height: 24),
              Text(
                'Verification Pending',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your documents are being reviewed by the Nsuride Safety Team. You will receive a notification once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
