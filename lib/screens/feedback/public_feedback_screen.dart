import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PublicFeedbackScreen extends StatefulWidget {
  const PublicFeedbackScreen({super.key});

  @override
  State<PublicFeedbackScreen> createState() => _PublicFeedbackScreenState();
}

class _PublicFeedbackScreenState extends State<PublicFeedbackScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _getSentiment(int rating) {
    if (rating >= 4) {
      return 'Satisfied';
    }

    if (rating == 3) {
      return 'Neutral';
    }

    return 'Not Satisfied';
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('customer_feedback').add({
        'customerName': _nameController.text.trim().isEmpty
            ? 'Anonymous'
            : _nameController.text.trim(),
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'sentiment': _getSentiment(_rating),
        'source': 'QR Feedback',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to submit feedback: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _submitted ? _buildThankYouCard() : _buildFeedbackCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 38,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'EÜ MART',
            style: GoogleFonts.baloo2(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1565C0),
            ),
          ),

          Text(
            'Customer Feedback',
            style: GoogleFonts.baloo2(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'We value your experience. Please tell us how we did today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'How satisfied are you with your experience?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;

              return IconButton(
                tooltip: '$star star${star == 1 ? '' : 's'}',
                onPressed: () {
                  setState(() {
                    _rating = star;
                  });
                },
                iconSize: 43,
                icon: Icon(
                  star <= _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFFFA000),
                ),
              );
            }),
          ),

          if (_rating > 0) ...[
            const SizedBox(height: 4),
            Text(
              _getSentiment(_rating),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _rating >= 4
                    ? const Color(0xFF16A34A)
                    : _rating == 3
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFDC2626),
              ),
            ),
          ],

          const SizedBox(height: 26),

          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Name (optional)',
              hintText: 'You may remain anonymous',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _commentController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Comment (optional)',
              hintText: 'Tell us about your experience...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 55),
                child: Icon(Icons.chat_bubble_outline_rounded),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submitFeedback,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _submitting ? 'Submitting...' : 'Submit Feedback',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Thank you for helping EÜ MART improve its service.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 50,
              color: Color(0xFF16A34A),
            ),
          ),

          const SizedBox(height: 22),

          Text(
            'Thank You!',
            style: GoogleFonts.baloo2(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your feedback has been submitted successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 8),

          const Text(
            'We appreciate you taking the time to help us improve our service.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
