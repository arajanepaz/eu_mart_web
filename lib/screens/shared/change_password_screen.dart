import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class _PasswordHoverCard extends StatefulWidget {
  final Widget child;

  const _PasswordHoverCard({required this.child});

  @override
  State<_PasswordHoverCard> createState() => _PasswordHoverCardState();
}

class _PasswordHoverCardState extends State<_PasswordHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2216385A)
                  : const Color(0x1016385A),
              blurRadius: _hovered ? 20 : 11,
              offset: Offset(0, _hovered ? 9 : 5),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _PasswordTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PasswordTip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFF1565C0), size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7D8998),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordSectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PasswordSectionIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _PasswordStrengthMeter extends StatelessWidget {
  final int score;
  final String label;
  final Color color;

  const _PasswordStrengthMeter({
    required this.score,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Password strength',
                style: TextStyle(
                  color: Color(0xFF607086),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: List.generate(
              5,
              (index) => Expanded(
                child: Container(
                  height: 7,
                  margin: EdgeInsets.only(right: index == 4 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: index < score ? color : const Color(0xFFE1E7EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;

  const _RequirementChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 15,
            color: Color(0xFF1565C0),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607086),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _message;
  bool _messageIsError = false;

  bool _validate() {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    String? currentError;
    String? newError;
    String? confirmError;

    if (current.isEmpty) {
      currentError = 'Current password is required.';
    }

    if (next.isEmpty) {
      newError = 'New password is required.';
    } else if (next.length < 6) {
      newError = 'Password must have at least 6 characters.';
    } else if (next == current) {
      newError = 'New password must be different.';
    }

    if (confirm.isEmpty) {
      confirmError = 'Confirm the new password.';
    } else if (confirm != next) {
      confirmError = 'Passwords do not match.';
    }

    setState(() {
      _currentError = currentError;
      _newError = newError;
      _confirmError = confirmError;
      _message = null;
    });

    return currentError == null && newError == null && confirmError == null;
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    if (!_validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      setState(() {
        _messageIsError = true;
        _message = 'Unable to verify the current account.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;

      setState(() {
        _messageIsError = false;
        _message = 'Password changed successfully.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String message;

      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'The current password is incorrect.';
          setState(() {
            _currentError = message;
          });
          break;
        case 'weak-password':
          message = 'The new password is too weak.';
          setState(() {
            _newError = message;
          });
          break;
        case 'requires-recent-login':
          message =
              'Please log out and sign in again '
              'before changing the password.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
        case 'network-request-failed':
          message = 'No internet connection.';
          break;
        default:
          message = error.message ?? 'Unable to change password.';
      }

      setState(() {
        _messageIsError = true;
        _message = message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _messageIsError = true;
        _message = 'Unable to change password: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback toggle,
    required String? errorText,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      suffixIcon: IconButton(
        tooltip: obscure ? 'Show password' : 'Hide password',
        onPressed: _loading ? null : toggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: const Color(0xFF7A8494),
        ),
      ),
      errorText: errorText,
      filled: true,
      fillColor: const Color(0xFFF7FAFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border(const Color(0xFFDDE6F1)),
      enabledBorder: border(
        errorText == null ? const Color(0xFFDDE6F1) : const Color(0xFFD32F2F),
      ),
      focusedBorder: border(
        errorText == null ? const Color(0xFF1565C0) : const Color(0xFFD32F2F),
        width: 2,
      ),
      errorBorder: border(const Color(0xFFD32F2F), width: 1.5),
      focusedErrorBorder: border(const Color(0xFFD32F2F), width: 2),
    );
  }

  int get _passwordStrength {
    final password = _newPasswordController.text;

    if (password.isEmpty) return 0;

    int score = 0;

    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }

    return score.clamp(0, 5);
  }

  String get _strengthLabel {
    return switch (_passwordStrength) {
      0 => 'Not entered',
      1 => 'Very weak',
      2 => 'Weak',
      3 => 'Fair',
      4 => 'Strong',
      _ => 'Very strong',
    };
  }

  Color get _strengthColor {
    return switch (_passwordStrength) {
      0 => const Color(0xFFB8C5D5),
      1 => const Color(0xFFD32F2F),
      2 => const Color(0xFFF57C00),
      3 => const Color(0xFFF59E0B),
      4 => const Color(0xFF159447),
      _ => const Color(0xFF00897B),
    };
  }

  void _clearErrors() {
    if (_currentError != null ||
        _newError != null ||
        _confirmError != null ||
        _message != null) {
      setState(() {
        _currentError = null;
        _newError = null;
        _confirmError = null;
        _message = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: const Color(0xFFF2F6FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x291565C0),
                        blurRadius: 20,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.password_outlined,
                        color: Colors.white,
                        size: 29,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Change Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Update the password used to access '
                              'your EÜ MART account.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 850;

                    final securityPanel = _PasswordHoverCard(
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFD7E7FA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0D47A1),
                                    Color(0xFF1976D2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Account Security',
                              style: TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user?.email ?? 'Current account',
                              style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _PasswordTip(
                              icon: Icons.lock_outline,
                              title: 'Verify current password',
                              subtitle:
                                  'Firebase requires reauthentication before the password can be updated.',
                            ),
                            const SizedBox(height: 13),
                            const _PasswordTip(
                              icon: Icons.password_outlined,
                              title: 'Use a new password',
                              subtitle:
                                  'The replacement password must be different from the current password.',
                            ),
                            const SizedBox(height: 13),
                            const _PasswordTip(
                              icon: Icons.verified_user_outlined,
                              title: 'Keep account access private',
                              subtitle:
                                  'Do not share the account password with unauthorized users.',
                            ),
                          ],
                        ),
                      ),
                    );

                    final form = _PasswordHoverCard(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFFBFDFF)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE1E9F3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                _PasswordSectionIcon(
                                  icon: Icons.lock_reset_outlined,
                                  color: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Update Credentials',
                                        style: TextStyle(
                                          color: Color(0xFF172033),
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Enter and confirm the new account password.',
                                        style: TextStyle(
                                          color: Color(0xFF8A95A4),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            TextField(
                              controller: _currentPasswordController,
                              enabled: !_loading,
                              obscureText: _obscureCurrent,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _clearErrors(),
                              decoration: _decoration(
                                label: 'Current Password',
                                icon: Icons.lock_outline,
                                obscure: _obscureCurrent,
                                toggle: () {
                                  setState(() {
                                    _obscureCurrent = !_obscureCurrent;
                                  });
                                },
                                errorText: _currentError,
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _newPasswordController,
                              enabled: !_loading,
                              obscureText: _obscureNew,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                _clearErrors();
                                setState(() {});
                              },
                              decoration: _decoration(
                                label: 'New Password',
                                icon: Icons.lock_reset_outlined,
                                obscure: _obscureNew,
                                toggle: () {
                                  setState(() {
                                    _obscureNew = !_obscureNew;
                                  });
                                },
                                errorText: _newError,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _PasswordStrengthMeter(
                              score: _passwordStrength,
                              label: _strengthLabel,
                              color: _strengthColor,
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _confirmPasswordController,
                              enabled: !_loading,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => _clearErrors(),
                              onSubmitted: (_) {
                                if (!_loading) {
                                  _changePassword();
                                }
                              },
                              decoration: _decoration(
                                label: 'Confirm New Password',
                                icon: Icons.verified_user_outlined,
                                obscure: _obscureConfirm,
                                toggle: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                                errorText: _confirmError,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _RequirementChip(
                                  label: 'At least 6 characters',
                                ),
                                _RequirementChip(
                                  label: 'Different from current',
                                ),
                                _RequirementChip(
                                  label: 'Must match confirmation',
                                ),
                              ],
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 16),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _messageIsError
                                      ? const Color(0xFFFFEBEE)
                                      : const Color(0xFFEAF8F0),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _messageIsError
                                        ? const Color(0xFFF3B8BE)
                                        : const Color(0xFFBCE2CB),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _messageIsError
                                          ? Icons.error_outline
                                          : Icons.check_circle_outline,
                                      color: _messageIsError
                                          ? const Color(0xFFD32F2F)
                                          : const Color(0xFF159447),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _message!,
                                        style: TextStyle(
                                          color: _messageIsError
                                              ? const Color(0xFFD32F2F)
                                              : const Color(0xFF168653),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFF9DB7D4,
                                  ),
                                  elevation: 0,
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
                                    : const Icon(
                                        Icons.security_update_good_outlined,
                                      ),
                                label: Text(
                                  _loading ? 'UPDATING...' : 'UPDATE PASSWORD',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: securityPanel),
                          const SizedBox(width: 18),
                          Expanded(flex: 3, child: form),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        securityPanel,
                        const SizedBox(height: 18),
                        form,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
