import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _FeedbackHoverCard extends StatefulWidget {
  final Widget child;

  const _FeedbackHoverCard({required this.child});

  @override
  State<_FeedbackHoverCard> createState() => _FeedbackHoverCardState();
}

class _FeedbackHoverCardState extends State<_FeedbackHoverCard> {
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
          borderRadius: BorderRadius.circular(18),
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

class _FeedbackCountPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _FeedbackCountPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  final String name;
  final String comment;
  final int rating;
  final String sentiment;
  final String formattedDate;
  final Color color;
  final IconData icon;
  final Widget stars;

  const _FeedbackCard({
    required this.name,
    required this.comment,
    required this.rating,
    required this.sentiment,
    required this.formattedDate,
    required this.color,
    required this.icon,
    required this.stars,
  });

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, widget.color.withValues(alpha: 0.025)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.30)
                : const Color(0xFFE1E9F3),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2016385A)
                  : const Color(0x0F16385A),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(widget.icon, color: widget.color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.sentiment,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.rating > 0) ...[
                    const SizedBox(height: 6),
                    widget.stars,
                  ],
                  const SizedBox(height: 9),
                  Text(
                    widget.comment.isEmpty
                        ? 'No written comment.'
                        : widget.comment,
                    style: const TextStyle(
                      color: Color(0xFF536274),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        size: 15,
                        color: Color(0xFF8A95A4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF8A95A4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackEmptyState extends StatelessWidget {
  const _FeedbackEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.88, end: 1),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_chat_unread_outlined,
              size: 62,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No customer feedback found',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another search or feedback filter.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerFeedbackScreen extends StatefulWidget {
  const CustomerFeedbackScreen({super.key});

  @override
  State<CustomerFeedbackScreen> createState() => _CustomerFeedbackScreenState();
}

class _CustomerFeedbackScreenState extends State<CustomerFeedbackScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    final months = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} ${date.day}, ${date.year} • '
        '$hour:$minute $period';
  }

  int _readRating(Map<String, dynamic> data) {
    final value =
        data['rating'] ??
        data['stars'] ??
        data['score'] ??
        data['satisfactionRating'];

    if (value is num) {
      return value.round().clamp(1, 5);
    }

    return int.tryParse(value?.toString() ?? '')?.clamp(1, 5) ?? 0;
  }

  String _readComment(Map<String, dynamic> data) {
    return (data['comment'] ??
            data['feedback'] ??
            data['message'] ??
            data['review'] ??
            '')
        .toString()
        .trim();
  }

  String _readCustomerName(Map<String, dynamic> data) {
    final name =
        (data['customerName'] ??
                data['name'] ??
                data['customer'] ??
                'Anonymous Customer')
            .toString()
            .trim();

    return name.isEmpty ? 'Anonymous Customer' : name;
  }

  String _sentiment(Map<String, dynamic> data, int rating) {
    final savedSentiment =
        (data['sentiment'] ??
                data['classification'] ??
                data['satisfaction'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();

    if (savedSentiment.contains('not satisfied') ||
        savedSentiment.contains('dissatisfied') ||
        savedSentiment.contains('negative')) {
      return 'Not Satisfied';
    }

    if (savedSentiment.contains('satisfied') ||
        savedSentiment.contains('positive')) {
      return 'Satisfied';
    }

    if (savedSentiment.contains('neutral')) {
      return 'Neutral';
    }

    if (rating >= 4) return 'Satisfied';
    if (rating > 0 && rating <= 2) return 'Not Satisfied';
    return 'Neutral';
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final rating = _readRating(data);
    final sentiment = _sentiment(data, rating);

    final searchable = [
      _readCustomerName(data),
      _readComment(data),
      sentiment,
      rating.toString(),
    ].join(' ').toLowerCase();

    return searchable.contains(_searchQuery);
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    if (_selectedFilter == 'All') return true;

    final rating = _readRating(data);
    return _sentiment(data, rating) == _selectedFilter;
  }

  Color _sentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Satisfied':
        return Colors.green;
      case 'Not Satisfied':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _sentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'Satisfied':
        return Icons.sentiment_satisfied_alt;
      case 'Not Satisfied':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.92, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: _FeedbackHoverCard(
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, color.withValues(alpha: 0.055)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.13)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.72)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF7A8494),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber.shade700,
          size: 19,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('customer_feedback')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load customer feedback.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final documents =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            );

        documents.sort((a, b) {
          final first = _readDate(a.data()['createdAt']);
          final second = _readDate(b.data()['createdAt']);

          if (first == null && second == null) return 0;
          if (first == null) return 1;
          if (second == null) return -1;

          return second.compareTo(first);
        });

        int satisfiedCount = 0;
        int neutralCount = 0;
        int notSatisfiedCount = 0;
        int ratingTotal = 0;
        int ratedCount = 0;

        for (final document in documents) {
          final data = document.data();
          final rating = _readRating(data);
          final sentiment = _sentiment(data, rating);

          if (sentiment == 'Satisfied') satisfiedCount++;
          if (sentiment == 'Neutral') neutralCount++;
          if (sentiment == 'Not Satisfied') {
            notSatisfiedCount++;
          }

          if (rating > 0) {
            ratingTotal += rating;
            ratedCount++;
          }
        }

        final averageRating = ratedCount == 0 ? 0.0 : ratingTotal / ratedCount;

        String overallResult = 'No Feedback Yet';

        if (documents.isNotEmpty) {
          if (satisfiedCount > notSatisfiedCount) {
            overallResult = 'Mostly Satisfied';
          } else if (notSatisfiedCount > satisfiedCount) {
            overallResult = 'Mostly Not Satisfied';
          } else {
            overallResult = 'Mixed Feedback';
          }
        }

        final filtered = documents.where((document) {
          final data = document.data();

          return _matchesSearch(data) && _matchesFilter(data);
        }).toList();

        return Container(
          color: const Color(0xFFF2F6FC),
          padding: const EdgeInsets.all(22),
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
                    Icon(Icons.forum_outlined, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Feedback',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Review ratings, customer comments, '
                            'and overall satisfaction.',
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
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  int count = 4;
                  if (constraints.maxWidth < 1050) {
                    count = 2;
                  }
                  if (constraints.maxWidth < 620) {
                    count = 1;
                  }

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: count,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    childAspectRatio: count == 4 ? 2.25 : 3.0,
                    children: [
                      _summaryCard(
                        title: 'Total Feedback',
                        value: '${documents.length}',
                        icon: Icons.reviews_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                      _summaryCard(
                        title: 'Average Rating',
                        value: averageRating == 0
                            ? 'No rating'
                            : '${averageRating.toStringAsFixed(1)} / 5',
                        icon: Icons.star_outline,
                        color: const Color(0xFFF59E0B),
                      ),
                      _summaryCard(
                        title: 'Satisfied',
                        value: '$satisfiedCount',
                        icon: Icons.sentiment_satisfied_alt,
                        color: const Color(0xFF159447),
                      ),
                      _summaryCard(
                        title: 'Overall Result',
                        value: overallResult,
                        icon: overallResult == 'Mostly Not Satisfied'
                            ? Icons.sentiment_dissatisfied
                            : Icons.insights_outlined,
                        color: overallResult == 'Mostly Not Satisfied'
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF7B1FA2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAF3FF), Color(0xFFF7FAFF)],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFD7E7FA)),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _FeedbackCountPill(
                      label: 'Satisfied',
                      value: satisfiedCount,
                      color: const Color(0xFF159447),
                      icon: Icons.sentiment_satisfied_alt,
                    ),
                    _FeedbackCountPill(
                      label: 'Neutral',
                      value: neutralCount,
                      color: const Color(0xFFF59E0B),
                      icon: Icons.sentiment_neutral,
                    ),
                    _FeedbackCountPill(
                      label: 'Not Satisfied',
                      value: notSatisfiedCount,
                      color: const Color(0xFFD32F2F),
                      icon: Icons.sentiment_dissatisfied,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;

                  final search = TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Search customer, comment, rating, or sentiment',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF1565C0),
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFF1565C0),
                          width: 2,
                        ),
                      ),
                    ),
                  );

                  final filters = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All'),
                        const SizedBox(width: 8),
                        _filterChip('Satisfied'),
                        const SizedBox(width: 8),
                        _filterChip('Neutral'),
                        const SizedBox(width: 8),
                        _filterChip('Not Satisfied'),
                      ],
                    ),
                  );

                  if (compact) {
                    return Column(
                      children: [search, const SizedBox(height: 12), filters],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 14),
                      filters,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const _FeedbackEmptyState()
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 11),
                        itemBuilder: (context, index) {
                          final data = filtered[index].data();

                          final name = _readCustomerName(data);
                          final comment = _readComment(data);
                          final rating = _readRating(data);
                          final sentiment = _sentiment(data, rating);
                          final date = _readDate(data['createdAt']);
                          final color = _sentimentColor(sentiment);

                          return _FeedbackCard(
                            name: name,
                            comment: comment,
                            rating: rating,
                            sentiment: sentiment,
                            formattedDate: _formatDate(date),
                            color: color,
                            icon: _sentimentIcon(sentiment),
                            stars: _stars(rating),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
