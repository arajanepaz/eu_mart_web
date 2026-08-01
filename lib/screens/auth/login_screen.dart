import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cashier/cashier_dashboard.dart';
import '../owner/owner_dashboard.dart';
import 'forgot_password_screen.dart';

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _checkingSession = true;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSavedSession();
    });
  }

  Future<void> _checkSavedSession() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _checkingSession = false);
      }
      return;
    }

    try {
      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        if (mounted) {
          setState(() => _checkingSession = false);
        }
        return;
      }

      await _openDashboardForUser(
        refreshedUser,
        showLoginErrors: false,
        loginMethod: 'saved_session',
        rememberMe: true,
      );
    } catch (error) {
      debugPrint('Saved login session could not be restored: $error');

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        setState(() => _checkingSession = false);
      }
    }
  }

  Future<void> _recordLoginActivity({
    required User user,
    required String role,
    required String loginMethod,
    required bool rememberMe,
    required String name,
  }) async {
    try {
      final loginAt = DateTime.now();

      final reference = await FirebaseFirestore.instance
          .collection('login_activity')
          .add({
            'userId': user.uid,
            'email': user.email ?? '',
            'name': name,
            'role': role,
            'loginMethod': loginMethod,
            'rememberMe': rememberMe,
            'sessionStatus': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'logoutAt': null,
            'sessionDurationSeconds': null,
          });

      final preferences = await SharedPreferences.getInstance();

      await preferences.setString('activeLoginActivityId', reference.id);

      await preferences.setInt(
        'activeLoginStartedAt',
        loginAt.millisecondsSinceEpoch,
      );
    } catch (error) {
      debugPrint('Unable to record login activity: $error');
    }
  }

  Future<void> _openDashboardForUser(
    User user, {
    bool showLoginErrors = true,
    String loginMethod = 'password',
    bool rememberMe = false,
  }) async {
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDocument.exists) {
      await FirebaseAuth.instance.signOut();
      throw Exception('User record was not found in Firestore.');
    }

    final data = userDocument.data() ?? <String, dynamic>{};

    final role = (data['role'] ?? '').toString().trim().toLowerCase();

    final isActive = data['isActive'] == true;

    if (!isActive) {
      await FirebaseAuth.instance.signOut();
      throw Exception('This account is currently disabled.');
    }

    await _recordLoginActivity(
      user: user,
      role: role,
      loginMethod: loginMethod,
      rememberMe: rememberMe,
      name: (data['name'] ?? data['fullName'] ?? user.email ?? 'User')
          .toString(),
    );

    if (!mounted) return;

    if (role == 'owner') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerDashboard()),
      );
      return;
    }

    if (role == 'cashier') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CashierDashboard()),
      );
      return;
    }

    await FirebaseAuth.instance.signOut();

    throw Exception('Unknown user role: $role');
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _emailError = email.isEmpty ? 'Email is required.' : null;
        _passwordError = password.isEmpty ? 'Password is required.' : null;
        _errorMessage = null;
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
        _emailError = null;
        _passwordError = null;
      });

      await FirebaseAuth.instance.setPersistence(
        _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Unable to load user account.');
      }

      await _openDashboardForUser(
        user,
        loginMethod: 'password',
        rememberMe: _rememberMe,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String message = 'Login failed.';
      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'user-not-found') {
        message = 'Incorrect email or password.';
      } else if (error.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (error.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else if (error.code == 'network-request-failed') {
        message = 'No internet connection.';
      } else if (error.message != null) {
        message = error.message!;
      } else if (error.code == 'unsupported-persistence-type') {
        message = 'This browser does not support the selected login session.';
      }

      setState(() {
        _errorMessage = message;

        if (error.code == 'invalid-email') {
          _emailError = 'Invalid email address.';
          _passwordError = null;
        } else if (error.code == 'invalid-credential' ||
            error.code == 'wrong-password' ||
            error.code == 'user-not-found') {
          _emailError = 'Incorrect email or password.';
          _passwordError = 'Incorrect email or password.';
        } else {
          _emailError = null;
          _passwordError = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required String? errorText,
    Widget? suffixIcon,
  }) {
    final hasError = errorText != null;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: hasError ? Colors.red : const Color(0xFF1565C0),
      ),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: const Color(0xFFF6F9FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFFD8E2EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFF1565C0),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _decorativeCircle({
    required double size,
    required Alignment alignment,
    required double opacity,
  }) {
    return Align(
      alignment: alignment,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.78, end: 1),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06377D), Color(0xFF0D57B7), Color(0xFF1985D8)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/images/grocery_overlay.png.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          _decorativeCircle(
            size: 310,
            alignment: const Alignment(-1.18, -1.12),
            opacity: 0.25,
          ),
          _decorativeCircle(
            size: 210,
            alignment: const Alignment(1.08, 1.08),
            opacity: 0.18,
          ),
          _decorativeCircle(
            size: 95,
            alignment: const Alignment(0.72, -0.70),
            opacity: 0.22,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 38),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(-35 * (1 - value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 30,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/eu_mart_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'EÜ MART',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 43,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Point-of-Sale Service Management System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'AI-Assisted Product Search and Basic '
                        'Business Monitoring',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _FeatureChip(
                            icon: Icons.point_of_sale_rounded,
                            label: 'Faster Checkout',
                          ),
                          _FeatureChip(
                            icon: Icons.inventory_2_outlined,
                            label: 'Stock Monitoring',
                          ),
                          _FeatureChip(
                            icon: Icons.auto_awesome_outlined,
                            label: 'AI Search',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9FBFF), Color(0xFFF0F5FC)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 445),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 720),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(35 * (1 - value), 0),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(34),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE5ECF5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A16395C),
                      blurRadius: 32,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x331565C0),
                            blurRadius: 14,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Sign in to continue to your EÜ MART account.',
                      style: TextStyle(
                        color: Color(0xFF7A8493),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_emailError != null || _errorMessage != null) {
                          setState(() {
                            _emailError = null;
                            _errorMessage = null;
                          });
                        }
                      },
                      decoration: _inputDecoration(
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        errorText: _emailError,
                      ),
                    ),
                    const SizedBox(height: 17),
                    TextField(
                      controller: _passwordController,
                      enabled: !_loading,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        if (_passwordError != null || _errorMessage != null) {
                          setState(() {
                            _passwordError = null;
                            _errorMessage = null;
                          });
                        }
                      },
                      onSubmitted: (_) {
                        if (!_loading) _login();
                      },
                      decoration: _inputDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        errorText: _passwordError,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              key: ValueKey<bool>(_obscurePassword),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 360;

                        final rememberWidget = InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: _loading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                  activeColor: const Color(0xFF1565C0),
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Color(0xFF556274),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        final forgotWidget = TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              rememberWidget,
                              Align(
                                alignment: Alignment.centerRight,
                                child: forgotWidget,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            rememberWidget,
                            const Spacer(),
                            forgotWidget,
                          ],
                        );
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: _errorMessage == null
                          ? const SizedBox.shrink()
                          : Container(
                              margin: const EdgeInsets.only(top: 7, bottom: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFCDD2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFC62828),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 17),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF9DB9D8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _loading
                              ? const Row(
                                  key: ValueKey('loading'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 21,
                                      height: 21,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'SIGNING IN...',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  key: ValueKey('login'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded),
                                    SizedBox(width: 9),
                                    Text(
                                      'SIGN IN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'SECURE ACCESS',
                            style: TextStyle(
                              color: Color(0xFF9AA5B3),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Authorized Owner and Cashier accounts only.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8A94A3),
                        fontSize: 11.5,
                      ),
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
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F7FC),
        body: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.85, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A16395C),
                    blurRadius: 25,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 17),
                  Text(
                    'Checking saved login session...',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 5, child: _buildBrandPanel()),
                Expanded(flex: 4, child: _buildLoginForm()),
              ],
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: _buildBrandPanel()),
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.18)),
              ),
              _buildLoginForm(),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
