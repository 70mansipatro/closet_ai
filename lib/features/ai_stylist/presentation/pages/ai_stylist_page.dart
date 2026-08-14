import 'dart:math' as math;

import 'package:closet_ai/core/theme/app_colors.dart';
import 'package:closet_ai/features/ai_stylist/application/chat_providers.dart';
import 'package:closet_ai/features/ai_stylist/domain/chat_models.dart';
import 'package:closet_ai/features/ai_stylist/presentation/widgets/stylist_recommendation_card.dart';
import 'package:closet_ai/features/subscription/presentation/widgets/premium_feature_lock.dart';
import 'package:closet_ai/features/wardrobe/application/wardrobe_state.dart';
import 'package:closet_ai/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const List<String> _quickPrompts = [
  'What should I wear today?',
  'Style my item',
  'Party outfit',
  'Office outfit',
  'College outfit',
  'Weather outfit',
  'Trip outfit',
  'Laundry advice',
];

class AiStylistPage extends ConsumerStatefulWidget {
  const AiStylistPage({super.key});

  @override
  ConsumerState<AiStylistPage> createState() => _AiStylistPageState();
}

class _AiStylistPageState extends ConsumerState<AiStylistPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(wardrobeControllerProvider).items.isEmpty) {
        ref.read(wardrobeControllerProvider.notifier).loadItems(limit: 200);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send([String? text]) {
    final message = text ?? _messageController.text;
    if (message.trim().isEmpty) return;
    _messageController.clear();
    ref.read(chatControllerProvider.notifier).sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatControllerProvider, (previous, next) {
      final gotNewMessage =
          previous == null || next.messages.length != previous.messages.length;
      if (gotNewMessage || next.isTyping) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('AI Stylist'),
        actions: [
          Builder(
            builder: (context) {
              final isWide = MediaQuery.sizeOf(context).width > 900;
              if (isWide) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Conversation history',
                icon: const Icon(Icons.history),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              );
            },
          ),
          IconButton(
            tooltip: 'New chat',
            onPressed: () => ref.read(chatControllerProvider.notifier).startNewChat(),
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(child: _ConversationList(onSelected: () => Navigator.of(context).maybePop())),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return Row(
              children: [
                if (isWide)
                  SizedBox(
                    width: 280,
                    child: _ConversationList(onSelected: () {}),
                  ),
                if (isWide) const VerticalDivider(width: 1),
                Expanded(child: _ChatPanel(onSend: _send, messageController: _messageController, scrollController: _scrollController)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConversationList extends ConsumerWidget {
  const _ConversationList({required this.onSelected});

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(chatControllerProvider);

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Conversations', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: state.conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Your past chats will show up here.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = state.conversations[index];
                      final isActive = conversation.id == state.conversationId;
                      return ListTile(
                        selected: isActive,
                        title: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          conversation.lastMessage.isEmpty
                              ? 'New conversation'
                              : conversation.lastMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Delete conversation',
                          onPressed: () => ref
                              .read(chatControllerProvider.notifier)
                              .deleteConversation(conversation.id),
                        ),
                        onTap: () {
                          ref
                              .read(chatControllerProvider.notifier)
                              .openConversation(conversation.id);
                          onSelected();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatPanel extends ConsumerWidget {
  const _ChatPanel({
    required this.onSend,
    required this.messageController,
    required this.scrollController,
  });

  final void Function([String? text]) onSend;
  final TextEditingController messageController;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(chatControllerProvider);

    if (state.isInitializing && state.messages.isEmpty && state.errorMessage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty && state.errorMessage != null) {
      return _FullScreenError(
        message: state.errorMessage!,
        isPremiumRequired: state.isPremiumRequired,
        onRetry: () => ref.read(chatControllerProvider.notifier).retry(),
      );
    }

    final inputDisabled = state.isPremiumRequired;

    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty
              ? _EmptyState(theme: theme)
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length) {
                      return const _TypingBubble();
                    }
                    return _MessageBubble(
                      message: state.messages[index],
                      onTryAnother: () {
                        final precedingUserText = _findPrecedingUserMessage(
                          state.messages,
                          index,
                        );
                        if (precedingUserText != null) {
                          onSend(precedingUserText);
                        }
                      },
                    );
                  },
                ),
        ),
        if (state.errorMessage != null && state.messages.isNotEmpty)
          _InlineErrorBanner(
            message: state.errorMessage!,
            onRetry: () => ref.read(chatControllerProvider.notifier).retry(),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!inputDisabled)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickPrompts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ActionChip(
                        label: Text(_quickPrompts[index]),
                        onPressed: () => onSend(_quickPrompts[index]),
                      ),
                    ),
                  ),
                if (inputDisabled)
                  const PremiumFeatureLock(
                    title: 'AI Stylist',
                    subtitle: 'Upgrade to keep chatting with your stylist this month.',
                  )
                else ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          decoration: const InputDecoration(
                            hintText: 'Ask your AI stylist...',
                          ),
                          onSubmitted: state.isSending ? null : (_) => onSend(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state.isSending ? null : () => onSend(),
                        icon: state.isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _findPrecedingUserMessage(
    List<ChatMessageModel> messages,
    int fromIndex,
  ) {
    for (var i = fromIndex - 1; i >= 0; i--) {
      if (messages[i].isUser) return messages[i].content;
    }
    return null;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Your AI Stylist', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Ask about outfits, weather, laundry, packing, and wardrobe ideas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenError extends StatelessWidget {
  const _FullScreenError({
    required this.message,
    required this.isPremiumRequired,
    required this.onRetry,
  });

  final String message;
  final bool isPremiumRequired;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPremiumRequired ? Icons.workspace_premium_outlined : Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            if (isPremiumRequired)
              GradientButton(
                label: 'Upgrade to Premium',
                icon: Icons.workspace_premium_outlined,
                variant: GradientButtonVariant.premium,
                expand: false,
                onPressed: onRetry,
              )
            else
              GradientButton(
                label: 'Retry',
                icon: Icons.refresh,
                expand: false,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onTryAnother});

  final ChatMessageModel message;
  final VoidCallback onTryAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final maxWidth = math.min(650.0, MediaQuery.sizeOf(context).width * 0.82);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? theme.colorScheme.primary : null,
              gradient: isUser
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brightBlue.withValues(alpha: 0.12),
                        AppColors.purple.withValues(alpha: 0.12),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: isUser
                  ? null
                  : Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isFallback)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Stylist AI is having trouble — safe suggestion shown',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isUser ? theme.colorScheme.onPrimary : null,
                  ),
                ),
                if (message.missingItems.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...message.missingItems.map(
                    (item) => Text(
                      '• $item',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUser
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isUser
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (message.recommendations.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final recommendation in message.recommendations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StylistRecommendationCard(
                        recommendation: recommendation,
                        onTryAnother: onTryAnother,
                      ),
                    ),
                  if (message.alternatives.isNotEmpty)
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('See other options'),
                        children: [
                          for (final alternative in message.alternatives)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: StylistRecommendationCard(
                                recommendation: alternative,
                                onTryAnother: onTryAnother,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brightBlue.withValues(alpha: 0.12),
              AppColors.purple.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('Typing...', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
