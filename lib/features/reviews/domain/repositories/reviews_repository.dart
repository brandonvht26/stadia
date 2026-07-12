abstract class ReviewsRepository {
  Future<void> submitReview({
    required String receptionId,
    required int rating,
    String? comment,
  });
}
