import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/chat_model.dart';
import '../repository/chat_repository.dart';

final chatListProvider = FutureProvider.autoDispose<List<ChatThreadModel>>((ref) async {
  final threads = await ref.read(chatRepositoryProvider).getThreads();
  threads.sort((a, b) {
    final aTime = a.updatedAt?.millisecondsSinceEpoch ?? 0;
    final bTime = b.updatedAt?.millisecondsSinceEpoch ?? 0;
    return bTime.compareTo(aTime);
  });
  return threads;
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncThreads = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: asyncThreads.when(
        data: (threads) {
          if (threads.isEmpty) {
            return const Center(child: Text('No messages yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              final title = thread.counterpart?.name ??
                  thread.counterpart?.storeName ??
                  'Conversation';
              final subtitle = thread.subject.isNotEmpty
                  ? thread.subject
                  : thread.lastMessage?.content ?? 'No messages yet.';

              return InkWell(
                onTap: () => context.push('/chat/${thread.id}'),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFF4EFE6),
                        child: Text(
                          title.isNotEmpty ? title[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Color(0xFF121A23),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                if (thread.unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121A23),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${thread.unreadCount}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF475569),
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              thread.updatedAt?.toLocal().toString() ?? 'Recently updated',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
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
            child: Text('Error loading messages: $e', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
