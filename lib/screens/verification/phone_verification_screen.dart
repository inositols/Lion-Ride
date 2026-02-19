import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../logic/verification/verification_bloc.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listener: (context, state) {
        if (state is VerificationOtpSent) {
          setState(() => _verificationId = state.verificationId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP Sent Successfully')),
          );
        }
        if (state is VerificationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF00382E),
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Phone Verification',
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _verificationId == null
                      ? 'Enter your phone number to receive a verification code.'
                      : 'Enter the 6-digit code sent to ${_phoneController.text}',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
                const SizedBox(height: 48),
                if (_verificationId == null) ...[
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+234 810 000 0000',
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  _buildButton(
                    onPressed: () {
                      if (_phoneController.text.isNotEmpty) {
                        context.read<VerificationBloc>().add(StartPhoneVerification(_phoneController.text));
                      }
                    },
                    text: 'SEND CODE',
                    isLoading: state is VerificationLoading,
                  ),
                ] else ...[
                  _buildTextField(
                    controller: _otpController,
                    label: 'Verification Code',
                    hint: '123456',
                    icon: Icons.lock_clock,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  _buildButton(
                    onPressed: () {
                      if (_otpController.text.length == 6) {
                        context.read<VerificationBloc>().add(SubmitOtp(_verificationId!, _otpController.text));
                      }
                    },
                    text: 'VERIFY & CONTINUE',
                    isLoading: state is VerificationLoading,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _verificationId = null),
                    child: const Text('Change Phone Number', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.yellowAccent),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.yellowAccent)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildButton({required VoidCallback onPressed, required String text, bool isLoading = false}) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00382E),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Color(0xFF00382E))
          : Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }
}
