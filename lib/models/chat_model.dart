class ChatCounterpartModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;
  final String? storeName;
  final String? slug;

  const ChatCounterpartModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
    this.storeName,
    this.slug,
  });

  factory ChatCounterpartModel.fromJson(Map<String, dynamic> json) {
    return ChatCounterpartModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['store_name'] ?? 'Conversation').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      role: json['role']?.toString(),
      storeName: json['store_name']?.toString(),
      slug: json['slug']?.toString(),
    );
  }
}

class ChatProductReferenceModel {
  final int id;
  final String title;
  final String? imageUrl;

  const ChatProductReferenceModel({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  factory ChatProductReferenceModel.fromJson(Map<String, dynamic> json) {
    return ChatProductReferenceModel(
      id: json['id'] ?? 0,
      title: (json['title'] ?? 'Product').toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class ChatMessageModel {
  final int id;
  final dynamic sender;
  final String content;
  final bool isRead;
  final bool isOwnMessage;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    this.sender,
    required this.content,
    this.isRead = false,
    this.isOwnMessage = false,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? 0,
      sender: json['sender'],
      content: json['content']?.toString() ?? '',
      isRead: json['is_read'] ?? false,
      isOwnMessage: json['is_own_message'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class ChatThreadModel {
  final int id;
  final dynamic vendor;
  final dynamic customer;
  final ChatProductReferenceModel? product;
  final ChatCounterpartModel? counterpart;
  final String subject;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ChatMessageModel> messages;

  const ChatThreadModel({
    required this.id,
    this.vendor,
    this.customer,
    this.product,
    this.counterpart,
    this.subject = 'Conversation',
    this.lastMessage,
    this.unreadCount = 0,
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    final counterpartJson = json['counterpart'];
    final lastMessageJson = json['last_message'];
    final messagesJson = json['messages'];

    return ChatThreadModel(
      id: json['id'] ?? 0,
      vendor: json['vendor'],
      customer: json['customer'],
      product: productJson is Map<String, dynamic>
          ? ChatProductReferenceModel.fromJson(productJson)
          : null,
      counterpart: counterpartJson is Map<String, dynamic>
          ? ChatCounterpartModel.fromJson(counterpartJson)
          : null,
      subject: (json['subject'] ?? 'Conversation').toString(),
      lastMessage: lastMessageJson is Map<String, dynamic>
          ? ChatMessageModel.fromJson(lastMessageJson)
          : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      messages: messagesJson is List
          ? messagesJson
              .whereType<Map<String, dynamic>>()
              .map(ChatMessageModel.fromJson)
              .toList()
          : const [],
    );
  }
}
