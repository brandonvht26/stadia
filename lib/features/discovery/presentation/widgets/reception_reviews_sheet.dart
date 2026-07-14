import 'dart:ui';
import 'package:flutter/material.dart';
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
  late Future<List<ReviewWithUserEntity>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _repository.getReceptionReviews(widget.receptionId);
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
                child: FutureBuilder<List<ReviewWithUserEntity>>(
                  future: _reviewsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
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

                    final reviews = snapshot.data ?? [];

                    if (reviews.isEmpty) {
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
                      itemCount: reviews.length,
                      separatorBuilder: (context, index) => Divider(
                        color: colorScheme.onSurface.withOpacity(0.05),
                        height: 32,
                      ),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
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
