import '../core/media_url.dart';

class ReviewModel {
  final int id;
  final dynamic product;
  final dynamic user;
  final int rating;
  final String comment;
  final String reviewerName;
  final String? reviewerAvatarUrl;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    this.product,
    this.user,
    required this.rating,
    this.comment = '',
    this.reviewerName = 'Anonymous',
    this.reviewerAvatarUrl,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json['customer'] ?? json['author'];
    return ReviewModel(
      id: json['id'] ?? 0,
      product: json['product'],
      user: user,
      rating: _readRating(json),
      comment: _readComment(json) ?? '',      
      reviewerName: _readReviewerName(json, user),
      reviewerAvatarUrl: _readReviewerAvatar(json, user),
      createdAt: _readCreatedAt(json),
    );
  }

  static int _readRating(Map<String, dynamic> json) {
    final value = json['rating'] ?? json['stars'] ?? json['rate'];
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String? _readComment(Map<String, dynamic> json) {
    final candidates = [
      json['comment'],
      json['review'],
      json['message'],
      json['description'],
    ];

    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static String _readReviewerName(Map<String, dynamic> json, dynamic user) {
    final directCandidates = [
      json['user_name'],
      json['username'],
      json['reviewer_name'],
      json['name'],
      json['email'],
    ];

    for (final value in directCandidates) {
      if (value is String && value.trim().isNotEmpty) {
        return _normalizeDisplayName(value);
      }
    }

    if (user is Map<String, dynamic>) {
      final firstName = user['first_name'] is String ? (user['first_name'] as String).trim() : '';
      final lastName = user['last_name'] is String ? (user['last_name'] as String).trim() : '';
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }

      final nestedCandidates = [
        user['name'],
        user['username'],
        user['email'],
        user['first_name'],
      ];
      for (final value in nestedCandidates) {
        if (value is String && value.trim().isNotEmpty) {
          return _normalizeDisplayName(value);
        }
      }
    }

    if (user is String && user.trim().isNotEmpty) {
      return _normalizeDisplayName(user);
    }

    return 'Anonymous';
  }

  static String? _readReviewerAvatar(Map<String, dynamic> json, dynamic user) {
    final directCandidates = [
      json['avatar'],
      json['avatar_url'],
      json['profile_picture'],
      json['profile_image'],
      json['image'],
    ];

    for (final value in directCandidates) {
      if (value is String && value.trim().isNotEmpty) {
        return resolveMediaUrl(value);
      }
    }

    if (user is Map<String, dynamic>) {
      final nestedCandidates = [
        user['avatar'],
        user['avatar_url'],
        user['profile_picture'],
        user['profile_image'],
        user['image'],
      ];
      for (final value in nestedCandidates) {
        if (value is String && value.trim().isNotEmpty) {
          return resolveMediaUrl(value);
        }
      }
    }

    return null;
  }

  static String _normalizeDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Anonymous';
    }
    if (trimmed.contains('@')) {
      return trimmed.split('@').first;
    }
    return trimmed;
  }

  static DateTime? _readCreatedAt(Map<String, dynamic> json) {
    final candidates = [
      json['created_at'],
      json['createdAt'],
      json['date'],
      json['timestamp'],
    ];

    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
