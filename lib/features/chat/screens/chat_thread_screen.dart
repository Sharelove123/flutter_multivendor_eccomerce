import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../models/chat_model.dart';
import '../../../models/user_model.dart';
import '../../auth/repository/auth_repository.dart';
import '../repository/chat_repository.dart';

final chatThreadProvider =
    FutureProvider.autoDispose.family<ChatThreadModel, int>((ref, threadId) async {
  return ref.read(chatRepositoryProvider).getThreadDetail(threadId);
});

final chatCurrentUserProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  return ref.read(authRepositoryProvider).getCurrentUser();
});

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.threadId});

  final int threadId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _msgController = TextEditingController();
  Timer? _pollingTimer;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  bool _socketConnected = false;
  bool _socketConnecting = false;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      ref.invalidate(chatThreadProvider(widget.threadId));
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _socketSubscription?.cancel();
    _channel?.sink.close();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _connectSocket() async {
    if (_socketConnecting || _socketConnected) {
      return;
    }

    setState(() => _socketConnecting = true);
    try {
      final wsUrl = await ref.read(chatRepositoryProvider).getSocketUrl(widget.threadId);
      if (wsUrl.isEmpty) {
        throw Exception('Socket URL is empty.');
      }

      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel = channel;

      await _socketSubscription?.cancel();
      _socketSubscription = channel.stream.listen(
        (event) {
          final payload = jsonDecode(event.toString());
          final type = payload['type']?.toString();

          if (type == 'chat.connected') {
            if (mounted) {
              setState(() {
                _socketConnected = true;
                _socketConnecting = false;
              });
            }
            return;
          }

          if (type == 'chat.message') {
            ref.invalidate(chatThreadProvider(widget.threadId));
            return;
          }

          if (type == 'chat.error' && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(payload['detail']?.toString() ?? 'Chat socket error')),
            );
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _socketConnected = false;
              _socketConnecting = false;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _socketConnected = false;
              _socketConnecting = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _socketConnected = false;
          _socketConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WebSocket connection failed: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) {
      return;
    }

    try {
      if (_socketConnected && _channel != null) {
        _channel!.sink.add(
          jsonEncode({
            'action': 'send_message',
            'content': text,
          }),
        );
      } else {
        await ref.read(chatRepositoryProvider).sendMessage(widget.threadId, text);
      }

      _msgController.clear();
      ref.invalidate(chatThreadProvider(widget.threadId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(chatThreadProvider(widget.threadId));
    final currentUserAsync = ref.watch(chatCurrentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: threadAsync.when(
          data: (thread) => Text(
            thread.counterpart?.name ?? 'Chat',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => const Text('Chat'),
          error: (_, __) => const Text('Chat'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _socketConnected
                      ? const Color(0x1A2F6F4F)
                      : (_socketConnecting ? const Color(0x1AF59E0B) : const Color(0x14000000)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _socketConnected
                      ? 'Live'
                      : (_socketConnecting ? 'Connecting' : 'Polling'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _socketConnected
                            ? const Color(0xFF2F6F4F)
                            : (_socketConnecting ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: currentUserAsync.when(
              data: (currentUser) => threadAsync.when(
                data: (thread) {
                  if (thread.messages.isEmpty) {
                    return const Center(child: Text('Say hi!'));
                  }

                  final messages = [...thread.messages]
                    ..sort((a, b) {
                      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
                      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
                      return aTime.compareTo(bTime);
                    });

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isOwn = _isOwnMessage(message, currentUser.id);

                      return Align(
                        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          margin: EdgeInsets.only(
                            bottom: 10,
                            left: isOwn ? 44 : 0,
                            right: isOwn ? 0 : 44,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isOwn ? const Color(0xFF121A23) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isOwn ? 20 : 6),
                              bottomRight: Radius.circular(isOwn ? 6 : 20),
                            ),
                            border: Border.all(
                              color: isOwn ? Colors.transparent : const Color(0x14000000),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x120F172A),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                softWrap: true,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isOwn ? Colors.white : const Color(0xFF121A23),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                message.createdAt?.toLocal().toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isOwn ? Colors.white70 : const Color(0xFF64748B),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error loading chat: $e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error loading user info: $e',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Type message...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOwnMessage(ChatMessageModel message, String currentUserId) {
    if (message.isOwnMessage) {
      return true;
    }

    final sender = message.sender;
    if (sender is Map<String, dynamic>) {
      final senderId = sender['id']?.toString();
      return senderId != null && senderId == currentUserId;
    }

    if (sender != null) {
      return sender.toString() == currentUserId;
    }

    return false;
  }
}
