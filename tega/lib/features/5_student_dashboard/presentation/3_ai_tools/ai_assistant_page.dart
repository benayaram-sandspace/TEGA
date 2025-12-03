import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tega/features/5_student_dashboard/data/ai_assistant_service.dart';
import 'package:tega/core/services/ai_assistant_cache_service.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final AIAssistantService _service = AIAssistantService();
  final AIAssistantCacheService _cacheService = AIAssistantCacheService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  final TextEditingController _titleController = TextEditingController();

  // Simple in-memory conversation list
  final List<_Conversation> _conversations = [];
  _Conversation? _active;

  bool _isSending = false;
  String? _sessionId;
  String _model = 'Gemini 2.0 Flash (Cloud - FREE)';

  List<AIMessage> get _messages => _active?.messages ?? [];

  // Responsive breakpoints
  double get mobileBreakpoint => 600;
  double get tabletBreakpoint => 1024;
  double get desktopBreakpoint => 1440;
  bool get isMobile => MediaQuery.of(context).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  bool get isDesktop =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  bool get isLargeDesktop =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  bool get isSmallScreen => MediaQuery.of(context).size.width < 400;
  bool get isWide => MediaQuery.of(context).size.width >= 900;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    await _cacheService.initialize();
    await _loadConversationsFromCache();
  }

  bool _isNoInternetError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        (error.toString().toLowerCase().contains('network') ||
            error.toString().toLowerCase().contains('connection') ||
            error.toString().toLowerCase().contains('internet') ||
            error.toString().toLowerCase().contains('failed host lookup') ||
            error.toString().toLowerCase().contains(
              'no address associated with hostname',
            ));
  }

  Future<void> _loadConversationsFromCache() async {
    try {
      final cachedConversations = await _cacheService.getConversations();
      if (cachedConversations != null && cachedConversations.isNotEmpty) {
        setState(() {
          _conversations.clear();
          for (var convData in cachedConversations) {
            final messages =
                (convData['messages'] as List?)
                    ?.map(
                      (m) => AIMessage(
                        role: m['role'] as String,
                        content: m['content'] as String,
                        timestamp:
                            DateTime.tryParse(
                              m['timestamp'] as String? ?? '',
                            ) ??
                            DateTime.now(),
                        sessionId: m['sessionId'] as String?,
                      ),
                    )
                    .toList() ??
                [];
            _conversations.add(
              _Conversation(
                id: convData['id'] as String,
                title: convData['title'] as String? ?? '',
                messages: messages,
              ),
            );
          }
        });

        // Restore active conversation
        final activeId = await _cacheService.getActiveConversationId();
        if (activeId != null) {
          final active = _conversations.firstWhere(
            (c) => c.id == activeId,
            orElse: () => _conversations.isNotEmpty
                ? _conversations.first
                : _Conversation(id: '', title: '', messages: []),
          );
          setState(() {
            _active = active;
          });
        } else if (_conversations.isNotEmpty) {
          setState(() {
            _active = _conversations.first;
          });
        }

        // Restore session ID
        final cachedSessionId = await _cacheService.getSessionId();
        if (cachedSessionId != null) {
          _sessionId = cachedSessionId;
        }
      }
    } catch (e) {
      // If cache loading fails, start fresh
    }
  }

  Future<void> _saveConversationsToCache() async {
    try {
      final conversationsData = _conversations
          .map(
            (conv) => {
              'id': conv.id,
              'title': conv.title,
              'messages': conv.messages
                  .map(
                    (msg) => {
                      'role': msg.role,
                      'content': msg.content,
                      'timestamp': msg.timestamp.toIso8601String(),
                      'sessionId': msg.sessionId,
                    },
                  )
                  .toList(),
            },
          )
          .toList();
      await _cacheService.setConversations(conversationsData);
      await _cacheService.setActiveConversationId(_active?.id);
      await _cacheService.setSessionId(_sessionId);
    } catch (e) {
      // If cache saving fails, continue without caching
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _chatScroll.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // New chats are created automatically on first message

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Create a conversation on-demand if none exists
    if (_active == null) {
      final conv = _Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        messages: [],
      );
      _conversations.insert(0, conv);
      _active = conv;
      _sessionId = null;
      _titleController.text = '';
    }

    setState(() {
      _active!.messages.add(
        AIMessage(role: 'user', content: text, timestamp: DateTime.now()),
      );
      _isSending = true;
      _inputController.clear();
      if (_active!.title.trim().isEmpty && text.isNotEmpty) {
        _active!.title = text.length > 28 ? '${text.substring(0, 28)}…' : text;
      }
    });

    // Save to cache after adding user message
    _saveConversationsToCache();

    await Future.delayed(const Duration(milliseconds: 50));
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(text, sessionId: _sessionId);
      setState(() {
        _sessionId = reply.sessionId ?? _sessionId;
        _active!.messages.add(reply);
      });
      // Save to cache after receiving reply
      _saveConversationsToCache();
    } catch (e) {
      // Check if it's a network/internet error
      final errorMessage = _isNoInternetError(e)
          ? 'No internet connection. Please check your connection and try again.'
          : 'Sorry, I could not process that. Please try again.';

      setState(() {
        _active!.messages.add(
          AIMessage(
            role: 'assistant',
            content: errorMessage,
            timestamp: DateTime.now(),
          ),
        );
      });
      // Save to cache even on error
      _saveConversationsToCache();
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!_chatScroll.hasClients) return;
    _chatScroll.animateTo(
      _chatScroll.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar (hidden on small screens)
            if (isWide) _buildSidebar(),
            // Main chat area
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  SizedBox(
                    height: isLargeDesktop
                        ? 12
                        : isDesktop
                        ? 10
                        : isTablet
                        ? 9
                        : isSmallScreen
                        ? 6
                        : 8,
                  ),
                  Expanded(child: _buildChatArea()),
                  _buildComposer(),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: isWide ? null : Drawer(child: _buildSidebar()),
    );
  }

  // Sidebar
  Widget _buildSidebar() {
    return Container(
      width: isLargeDesktop
          ? 360
          : isDesktop
          ? 320
          : isTablet
          ? 280
          : 300,
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
              isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
              isLargeDesktop
                  ? 24
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 18
                  : isSmallScreen
                  ? 12
                  : 16,
              isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : isSmallScreen
                      ? 14
                      : 16,
                  backgroundColor: const Color(0xFF22C55E),
                  child: Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 18
                        : isTablet
                        ? 17
                        : isSmallScreen
                        ? 14
                        : 16,
                  ),
                ),
                SizedBox(
                  width: isLargeDesktop
                      ? 14
                      : isDesktop
                      ? 12
                      : isTablet
                      ? 11
                      : isSmallScreen
                      ? 6
                      : 10,
                ),
                Text(
                  'TEGA AI',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w700,
                    fontSize: isLargeDesktop
                        ? 20
                        : isDesktop
                        ? 18
                        : isTablet
                        ? 17
                        : isSmallScreen
                        ? 14
                        : 16,
                  ),
                ),
                const Spacer(),
                // Removed sidebar New Chat button
              ],
            ),
          ),
          Divider(
            color: Theme.of(context).dividerColor,
            height: isLargeDesktop || isDesktop
                ? 1.5
                : isTablet
                ? 1.2
                : isSmallScreen
                ? 0.8
                : 1,
            thickness: isLargeDesktop || isDesktop
                ? 1.5
                : isTablet
                ? 1.2
                : isSmallScreen
                ? 0.8
                : 1,
          ),
          Expanded(
            child: _conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        isLargeDesktop
                            ? 32
                            : isDesktop
                            ? 24
                            : isTablet
                            ? 20
                            : isSmallScreen
                            ? 16
                            : 20,
                      ),
                      child: Text(
                        'No conversations yet',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: isLargeDesktop
                              ? 16
                              : isDesktop
                              ? 15
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 11
                              : 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      vertical: isLargeDesktop
                          ? 12
                          : isDesktop
                          ? 10
                          : isTablet
                          ? 9
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                    itemCount: _conversations.length,
                    itemBuilder: (context, i) {
                      final c = _conversations[i];
                      final selected = identical(c, _active);
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isLargeDesktop
                              ? 20
                              : isDesktop
                              ? 16
                              : isTablet
                              ? 14
                              : isSmallScreen
                              ? 8
                              : 12,
                          vertical: isLargeDesktop
                              ? 8
                              : isDesktop
                              ? 6
                              : isTablet
                              ? 5
                              : isSmallScreen
                              ? 2
                              : 4,
                        ),
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: Theme.of(context).iconTheme.color,
                          size: isLargeDesktop
                              ? 22
                              : isDesktop
                              ? 20
                              : isTablet
                              ? 19
                              : isSmallScreen
                              ? 16
                              : 18,
                        ),
                        title: Text(
                          c.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: isLargeDesktop || isDesktop
                              ? 2
                              : isTablet
                              ? 2
                              : 1,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: isLargeDesktop
                                ? 16
                                : isDesktop
                                ? 15
                                : isTablet
                                ? 14
                                : isSmallScreen
                                ? 11
                                : 13,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _active = c;
                          });
                          _saveConversationsToCache();
                        },
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).disabledColor,
                            size: isLargeDesktop
                                ? 22
                                : isDesktop
                                ? 20
                                : isTablet
                                ? 19
                                : isSmallScreen
                                ? 16
                                : 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _conversations.removeAt(i);
                              if (_active == c) {
                                _active = _conversations.isNotEmpty
                                    ? _conversations.first
                                    : null;
                              }
                            });
                            _saveConversationsToCache();
                          },
                          padding: EdgeInsets.all(
                            isLargeDesktop
                                ? 12
                                : isDesktop
                                ? 10
                                : isTablet
                                ? 9
                                : isSmallScreen
                                ? 6
                                : 8,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Top action bar
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDesktop
            ? 20
            : isDesktop
            ? 16
            : isTablet
            ? 14
            : isSmallScreen
            ? 10
            : 12,
        vertical: isLargeDesktop
            ? 14
            : isDesktop
            ? 12
            : isTablet
            ? 11
            : isSmallScreen
            ? 8
            : 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: isLargeDesktop || isDesktop
                ? 1.5
                : isTablet
                ? 1.2
                : isSmallScreen
                ? 0.8
                : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Model selector (visual only)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeDesktop
                  ? 14
                  : isDesktop
                  ? 12
                  : isTablet
                  ? 11
                  : isSmallScreen
                  ? 8
                  : 10,
              vertical: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 12
                    : isDesktop
                    ? 10
                    : isTablet
                    ? 9
                    : isSmallScreen
                    ? 6
                    : 8,
              ),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  size: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : isSmallScreen
                      ? 14
                      : 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                SizedBox(
                  width: isLargeDesktop || isDesktop
                      ? 8
                      : isTablet
                      ? 7
                      : isSmallScreen
                      ? 4
                      : 6,
                ),
                Text(
                  _model,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: isLargeDesktop
                        ? 15
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                ),
                SizedBox(
                  width: isLargeDesktop || isDesktop
                      ? 8
                      : isTablet
                      ? 7
                      : isSmallScreen
                      ? 4
                      : 6,
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).iconTheme.color,
                  size: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : isSmallScreen
                      ? 14
                      : 16,
                ),
              ],
            ),
          ),
          SizedBox(
            width: isLargeDesktop
                ? 12
                : isDesktop
                ? 10
                : isTablet
                ? 9
                : isSmallScreen
                ? 6
                : 8,
          ),
        ],
      ),
    );
  }

  // Chat messages
  Widget _buildChatArea() {
    if (_active == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(
            isLargeDesktop
                ? 48
                : isDesktop
                ? 32
                : isTablet
                ? 28
                : isSmallScreen
                ? 20
                : 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: isLargeDesktop
                    ? 80
                    : isDesktop
                    ? 64
                    : isTablet
                    ? 56
                    : isSmallScreen
                    ? 48
                    : 56,
                color: Theme.of(context).disabledColor,
              ),
              SizedBox(
                height: isLargeDesktop
                    ? 24
                    : isDesktop
                    ? 20
                    : isTablet
                    ? 18
                    : isSmallScreen
                    ? 12
                    : 16,
              ),
              Text(
                'Start a new chat to begin',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: isLargeDesktop
                      ? 22
                      : isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : isSmallScreen
                      ? 14
                      : 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _chatScroll,
      padding: EdgeInsets.fromLTRB(
        isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 16
            : 24,
        isLargeDesktop
            ? 12
            : isDesktop
            ? 10
            : isTablet
            ? 9
            : isSmallScreen
            ? 6
            : 8,
        isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 16
            : 24,
        isLargeDesktop
            ? 32
            : isDesktop
            ? 28
            : isTablet
            ? 24
            : isSmallScreen
            ? 16
            : 24,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: isLargeDesktop
                  ? 12
                  : isDesktop
                  ? 10
                  : isTablet
                  ? 9
                  : isSmallScreen
                  ? 6
                  : 8,
            ),
            padding: EdgeInsets.symmetric(
              vertical: isLargeDesktop
                  ? 16
                  : isDesktop
                  ? 14
                  : isTablet
                  ? 13
                  : isSmallScreen
                  ? 10
                  : 12,
              horizontal: isLargeDesktop
                  ? 20
                  : isDesktop
                  ? 18
                  : isTablet
                  ? 17
                  : isSmallScreen
                  ? 12
                  : 14,
            ),
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width *
                  (isLargeDesktop
                      ? 0.68
                      : isDesktop
                      ? 0.70
                      : isTablet
                      ? 0.72
                      : isSmallScreen
                      ? 0.85
                      : 0.75),
            ),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF6B5FFF) : const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(
                isLargeDesktop
                    ? 18
                    : isDesktop
                    ? 16
                    : isTablet
                    ? 15
                    : isSmallScreen
                    ? 10
                    : 14,
              ),
              border: Border.all(
                color: isUser
                    ? const Color(0xFF6B5FFF)
                    : const Color(0xFFE5E7EB),
                width: isLargeDesktop || isDesktop
                    ? 1.5
                    : isTablet
                    ? 1.2
                    : isSmallScreen
                    ? 0.8
                    : 1,
              ),
            ),
            child: msg.content.startsWith('No internet connection')
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        color: Colors.grey[600],
                        size: isLargeDesktop
                            ? 20
                            : isDesktop
                            ? 18
                            : isTablet
                            ? 17
                            : isSmallScreen
                            ? 14
                            : 16,
                      ),
                      SizedBox(
                        width: isLargeDesktop
                            ? 8
                            : isDesktop
                            ? 6
                            : isTablet
                            ? 5
                            : isSmallScreen
                            ? 4
                            : 6,
                      ),
                      Expanded(
                        child: Text(
                          msg.content,
                          style: TextStyle(
                            color: const Color(0xFF111827),
                            fontSize: isLargeDesktop
                                ? 17
                                : isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : isSmallScreen
                                ? 12
                                : 14,
                            height: isLargeDesktop || isDesktop
                                ? 1.5
                                : isTablet
                                ? 1.4
                                : isSmallScreen
                                ? 1.3
                                : 1.4,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF111827),
                      fontSize: isLargeDesktop
                          ? 17
                          : isDesktop
                          ? 16
                          : isTablet
                          ? 15
                          : isSmallScreen
                          ? 12
                          : 14,
                      height: isLargeDesktop || isDesktop
                          ? 1.5
                          : isTablet
                          ? 1.4
                          : isSmallScreen
                          ? 1.3
                          : 1.4,
                    ),
                  ),
          ),
        );
      },
    );
  }

  // Composer
  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isLargeDesktop
            ? 24
            : isDesktop
            ? 20
            : isTablet
            ? 18
            : isSmallScreen
            ? 12
            : 16,
        isLargeDesktop
            ? 14
            : isDesktop
            ? 12
            : isTablet
            ? 11
            : isSmallScreen
            ? 8
            : 10,
        isLargeDesktop
            ? 24
            : isDesktop
            ? 20
            : isTablet
            ? 18
            : isSmallScreen
            ? 12
            : 16,
        isLargeDesktop
            ? 20
            : isDesktop
            ? 18
            : isTablet
            ? 16
            : isSmallScreen
            ? 12
            : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: isLargeDesktop || isDesktop
                ? 1.5
                : isTablet
                ? 1.2
                : isSmallScreen
                ? 0.8
                : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: isLargeDesktop || isDesktop
                  ? 6
                  : isTablet
                  ? 5
                  : isSmallScreen
                  ? 4
                  : 5,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: isLargeDesktop
                    ? 17
                    : isDesktop
                    ? 16
                    : isTablet
                    ? 15
                    : isSmallScreen
                    ? 12
                    : 14,
              ),
              decoration: InputDecoration(
                hintText: 'Message TEGA AI...',
                hintStyle: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: isLargeDesktop
                      ? 17
                      : isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : isSmallScreen
                      ? 12
                      : 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8FC),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isLargeDesktop
                      ? 20
                      : isDesktop
                      ? 18
                      : isTablet
                      ? 17
                      : isSmallScreen
                      ? 12
                      : 14,
                  vertical: isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 13
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeDesktop
                        ? 16
                        : isDesktop
                        ? 14
                        : isTablet
                        ? 13
                        : isSmallScreen
                        ? 10
                        : 12,
                  ),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B5FFF),
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          SizedBox(
            width: isLargeDesktop
                ? 14
                : isDesktop
                ? 12
                : isTablet
                ? 11
                : isSmallScreen
                ? 6
                : 10,
          ),
          ElevatedButton(
            onPressed: _isSending ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5FFF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isLargeDesktop
                    ? 20
                    : isDesktop
                    ? 18
                    : isTablet
                    ? 17
                    : isSmallScreen
                    ? 12
                    : 16,
                vertical: isLargeDesktop
                    ? 16
                    : isDesktop
                    ? 14
                    : isTablet
                    ? 13
                    : isSmallScreen
                    ? 10
                    : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  isLargeDesktop
                      ? 16
                      : isDesktop
                      ? 14
                      : isTablet
                      ? 13
                      : isSmallScreen
                      ? 10
                      : 12,
                ),
              ),
              elevation: 0,
            ),
            child: Icon(
              Icons.send_rounded,
              size: isLargeDesktop
                  ? 22
                  : isDesktop
                  ? 20
                  : isTablet
                  ? 19
                  : isSmallScreen
                  ? 16
                  : 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _Conversation {
  final String id;
  String title;
  final List<AIMessage> messages;

  _Conversation({
    required this.id,
    required this.title,
    required this.messages,
  });
}
