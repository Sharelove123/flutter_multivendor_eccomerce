import 'package:flutter_dotenv/flutter_dotenv.dart';

String? resolveMediaUrl(dynamic value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final extractedAbsoluteUrl = _extractAbsoluteUrl(trimmed);
  if (extractedAbsoluteUrl != null) {
    return extractedAbsoluteUrl;
  }

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }

  final baseUrl = dotenv.env['API_BASE_URL']?.trim();
  if (baseUrl == null || baseUrl.isEmpty) {
    return trimmed;
  }

  final normalizedBaseUrl = baseUrl.endsWith('/')
      ? baseUrl
      : '$baseUrl/';
  final baseUri = Uri.tryParse(normalizedBaseUrl);
  if (baseUri == null) {
    return trimmed;
  }

  final relativePath = trimmed.startsWith('/')
      ? trimmed.substring(1)
      : trimmed;

  return baseUri.resolve(relativePath).toString();
}

String? _extractAbsoluteUrl(String value) {
  final httpsIndex = value.indexOf('https://');
  if (httpsIndex >= 0) {
    return value.substring(httpsIndex).trim();
  }

  final httpIndex = value.indexOf('http://');
  if (httpIndex >= 0) {
    return value.substring(httpIndex).trim();
  }

  return null;
}
