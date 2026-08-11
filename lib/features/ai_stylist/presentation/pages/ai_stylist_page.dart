import 'package:closet_ai/features/ai_stylist/data/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiStylistPage extends ConsumerStatefulWidget {
  const AiStylistPage({super.key});

  @override
  ConsumerState<AiStylistPage> createState() => _AiStylistPageState();
}

class _AiStylistPageState extends ConsumerState<AiStylistPage> {
  final ChatRepository _repository = ChatRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _conversationId;
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _createConversation();
    await _loadConversations();
  }

  Future<void> _createConversation() async {
    try {
      final response = await _repository.createConversation(
        title: 'New stylist chat',
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        setState(() {
          _conversationId = data['_id']?.toString();
        });
        await _loadMessages();
      }
    } catch (_) {
      setState(() => _error = 'Unable to start a chat right now.');
    }
  }

  Future<void> _loadConversations() async {
    try {
      final response = await _repository.listConversations();
      final data = response['data'];
      if (data is List) {
        setState(() {
          _conversations.clear();
          _conversations.addAll(
            data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList(),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    try {
      final response = await _repository.listMessages(_conversationId!);
      final data = response['data'];
      if (data is List) {
        setState(() {
          _messages.clear();
          _messages.addAll(
            data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList(),
          );
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    setState(() {
      _isLoading = true;
      _isTyping = true;
      _error = null;
    });

    _messageController.clear();

    try {
      await _repository.sendMessage(_conversationId!, text);
      await _loadMessages();
      await _loadConversations();
    } catch (_) {
      setState(
        () => _error = 'The stylist could not respond. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isTyping = false;
        });
      }
    }
  }

  Future<void> _newChat() async {
    setState(() {
      _messages.clear();
      _conversationId = null;
      _error = null;
    });
    await _createConversation();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Stylist'),
        actions: [
          IconButton(
            onPressed: _newChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return Row(
              children: [
                if (isWide)
                  SizedBox(width: 280, child: _buildConversationList(theme)),
                Expanded(child: _buildChatPanel(theme)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationList(ThemeData theme) {
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
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                final title =
                    conversation['title']?.toString() ?? 'Conversation';
                final lastMessage =
                    conversation['lastMessage']?.toString() ?? '';
                return ListTile(
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    lastMessage.isEmpty ? 'New conversation' : lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _conversationId = conversation['_id']?.toString();
                      _messages.clear();
                    });
                    _loadMessages();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your AI Stylist',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask about outfits, weather, laundry, packing, and wardrobe ideas.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingBubble(theme);
                    }
                    final message = _messages[index];
                    final isUser = message['role'] == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: const BoxConstraints(maxWidth: 650),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['content']?.toString() ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isUser
                                    ? theme.colorScheme.onPrimary
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(message['createdAt']),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isUser
                                    ? theme.colorScheme.onPrimary.withValues(
                                        alpha: 0.7,
                                      )
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _quickActionChip('What should I wear?'),
                    _quickActionChip('Style an item'),
                    _quickActionChip('Weather outfit'),
                    _quickActionChip('Laundry'),
                    _quickActionChip('Trip packing'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask your AI stylist...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingBubble(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
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

  Widget _quickActionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          _messageController.text = text;
          _sendMessage();
        },
      ),
    );
  }

  String _formatTime(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
