import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/review_with_user_entity.dart';
import '../../data/repositories/discovery_repository_impl.dart';

class ReceptionReviewsSheet extends StatefulWidget {
  final String receptionId;
  final int totalReviews;
  final ScrollController? scrollController;

  const ReceptionReviewsSheet({
    super.key,
    required this.receptionId,
    required this.totalReviews,
    this.scrollController,
  });

  @override
  State<ReceptionReviewsSheet> createState() => _ReceptionReviewsSheetState();
}

class _ReceptionReviewsSheetState extends State<ReceptionReviewsSheet> {
  final DiscoveryRepositoryImpl _repository = DiscoveryRepositoryImpl();
  List<ReviewWithUserEntity> _reviews = [];
  bool _isLoading = true;
  String? _error;
  RealtimeChannel? _reviewsChannel;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _initRealtime();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviews = await _repository.getReceptionReviews(widget.receptionId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _initRealtime() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final suffix = currentUserId ?? DateTime.now().millisecondsSinceEpoch.toString();

    _reviewsChannel = Supabase.instance.client.channel('reception-reviews-live-${widget.receptionId}-$suffix');
    _reviewsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'reviews',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'reception_id',
        value: widget.receptionId,
      ),
      callback: (payload) async {
        if (!mounted) return;
        final newRecord = payload.newRecord;
        final reviewId = newRecord['id'];
        
        try {
          // Fetch the specific review with its JOINs
          final data = await Supabase.instance.client
              .from('reviews')
              .select('*, profiles(first_name, last_name, avatar_url)')
              .eq('id', reviewId)
              .single();
              
          if (!mounted) return;
          
          final profile = data['profiles'];
          final firstName = profile['first_name'] ?? '';
          final lastName = profile['last_name'] ?? '';
          final userName = '$firstName $lastName'.trim();
          
          final newReview = ReviewWithUserEntity(
            userName: userName.isEmpty ? 'Usuario Desconocido' : userName,
            rating: (data['rating'] as num).toDouble(),
            comment: data['comment'],
            createdAt: DateTime.parse(data['created_at']),
          );

          setState(() {
            _reviews.insert(0, newReview);
          });
        } catch (e) {
          debugPrint('Error fetching specific review for realtime: $e');
        }
      },
    ).subscribe();
  }

  @override
  void dispose() {
    if (_reviewsChannel != null) {
      Supabase.instance.client.removeChannel(_reviewsChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.1), colorScheme.surface.withValues(alpha: 0.85)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reseñas (${widget.totalReviews})',
                    style: textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: colorScheme.onSurface.withOpacity(0.08)),

              Flexible(
                child: Builder(
                  builder: (context) {
                    if (_isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (_error != null) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Error al cargar reseñas',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      );
                    }

                    if (_reviews.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aún no hay reseñas para este lugar',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      itemCount: _reviews.length,
                      separatorBuilder: (context, index) => Divider(
                        color: colorScheme.onSurface.withOpacity(0.05),
                        height: 32,
                      ),
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return _buildReviewCard(review, colorScheme, textTheme);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    )));
  }

  Widget _buildReviewCard(ReviewWithUserEntity review, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              review.userName,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              review.formattedDate,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < review.rating ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.amber,
            );
          }),
        ),
        if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            review.comment!.trim(),
            style: textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
