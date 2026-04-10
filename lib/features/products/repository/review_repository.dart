import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../models/review_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.read(dioProvider));
});

class ReviewRepository {
  final Dio _dio;
  ReviewRepository(this._dio);

  Future<List<ReviewModel>> getProductReviews(int productId) async {
    final response = await _dio.get('/api/reviews/product/$productId/');
    final payload = response.data;
    final items = _extractReviewItems(payload);
    return items.map(ReviewModel.fromJson).toList();
  }

  Future<void> submitReview(int productId, int rating, String comment) async {
    final normalizedComment = comment.trim();
    if (normalizedComment.isEmpty) {
      throw Exception('Comment cannot be empty.');
    }

    final candidates = <Map<String, dynamic>>[
      {
        'rating': rating,
        'comment': normalizedComment,
      },
      {
        'rating': rating,
        'comment': normalizedComment,
        'product': productId,
      },
      {
        'rating': rating,
        'review': normalizedComment,
      },
      {
        'rating': rating,
        'review': normalizedComment,
        'product': productId,
      },
    ];

    DioException? lastError;

    for (final payload in candidates) {
      try {
        await _dio.post('/api/reviews/product/$productId/', data: payload);
        return;
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode != 400) {
          throw Exception(_extractErrorMessage(e));
        }
      }
    }

    throw Exception(_extractErrorMessage(lastError));
  }

  String _extractErrorMessage(DioException? e) {
    if (e == null) {
      return 'Unable to submit review.';
    }

    final data = e.response?.data;
    if (data is Map && data.isNotEmpty) {
      final firstKey = data.keys.first;
      final firstValue = data[firstKey];
      if (firstValue is List && firstValue.isNotEmpty) {
        return '$firstKey: ${firstValue.first}';
      }
      return '$firstKey: $firstValue';
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return e.message ?? 'Unable to submit review.';
  }

  List<Map<String, dynamic>> _extractReviewItems(dynamic payload) {
    if (payload is List) {
      return payload
          .map(_asStringKeyedMap)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    if (payload is Map) {
      final map = _asStringKeyedMap(payload);
      if (map == null) {
        return const [];
      }

      for (final key in const [
        'results',
        'reviews',
        'data',
        'items',
        'product_reviews',
      ]) {
        final value = map[key];
        if (value is List) {
          return value
              .map(_asStringKeyedMap)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }

      // Some APIs return a single review object.
      if (map.containsKey('id') || map.containsKey('rating')) {
        return [map];
      }
    }

    return const [];
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }

    return null;
  }
}
