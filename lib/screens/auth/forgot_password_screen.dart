import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;

  bool _loading = false;
  bool _sent = false;
  String? _emailError;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _sendResetLink() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required.';
        _message = null;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Enter a valid email address.';
        _message = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _emailError = null;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() {
        _sent = true;
        _messageIsError = false;
        _message =
            'Password reset link sent to $email. '
            'Check the inbox and spam folder.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String message;

      switch (error.code) {
        case 'invalid-email':
          message = 'Enter a valid email address.';
          break;
        case 'user-not-found':
          message = 'No registered account was found for this email.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'No internet connection. Check the network and try again.';
          break;
        default:
          message = error.message ?? 'Unable to send reset link.';
      }

      setState(() {
        _messageIsError = true;
        _message = message;

        if (error.code == 'invalid-email' || error.code == 'user-not-found') {
          _emailError = message;
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _messageIsError = true;
        _message = 'Unable to send reset link: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1565C0),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFFEAF2FF),
                      child: Icon(
                        Icons.lock_reset_outlined,
                        color: Color(0xFF1565C0),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Forgot Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the registered email address. '
                      'Firebase will send a secure password reset link.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        if (_emailError != null || _message != null) {
                          setState(() {
                            _emailError = null;
                            _message = null;
                            _sent = false;
                          });
                        }
                      },
                      onSubmitted: (_) {
                        if (!_loading) {
                          _sendResetLink();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        errorText: _emailError,
                        filled: true,
                        fillColor: const Color(0xFFF7F9FC),
                        border: _border(const Color(0xFFD5DCE5)),
                        enabledBorder: _border(
                          _emailError == null
                              ? const Color(0xFFD5DCE5)
                              : Colors.red,
                        ),
                        focusedBorder: _border(
                          _emailError == null
                              ? const Color(0xFF1565C0)
                              : Colors.red,
                          width: 2,
                        ),
                        errorBorder: _border(Colors.red, width: 1.5),
                        focusedErrorBorder: _border(Colors.red, width: 2),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _messageIsError
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _messageIsError
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _messageIsError
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: _messageIsError
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: _messageIsError
                                      ? Colors.red
                                      : Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_sent ? Icons.refresh : Icons.send_outlined),
                        label: Text(
                          _loading
                              ? 'SENDING...'
                              : _sent
                              ? 'SEND AGAIN'
                              : 'SEND RESET LINK',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('BACK TO LOGIN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
