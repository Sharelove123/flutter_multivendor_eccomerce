import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/review_model.dart';
import '../repository/review_repository.dart';

final productReviewsProvider = FutureProvider.autoDispose.family<List<ReviewModel>, int>((ref, productId) async {
  return ref.read(reviewRepositoryProvider).getProductReviews(productId);
});
