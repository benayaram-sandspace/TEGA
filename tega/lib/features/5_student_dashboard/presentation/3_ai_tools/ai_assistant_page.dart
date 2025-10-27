import 'package:flutter/material.dart';
import 'package:tega/features/5_student_dashboard/data/ai_assistant_service.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final AIAssistantService _service = AIAssistantService();
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

  @override
  void initState() {
    super.initState();
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

    await Future.delayed(const Duration(milliseconds: 50));
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(text, sessionId: _sessionId);
      setState(() {
        _sessionId = reply.sessionId ?? _sessionId;
        _active!.messages.add(reply);
      });
    } catch (e) {
      setState(() {
        _active!.messages.add(
          AIMessage(
            role: 'assistant',
            content: 'Sorry, I could not process that. Please try again.',
            timestamp: DateTime.now(),
          ),
        );
      });
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
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar (hidden on small screens)
            if (isWide) _buildSidebar(),
            // Main chat area
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(context, isWide),
                  const SizedBox(height: 8),
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
      width: 300,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF22C55E),
                  child: Icon(Icons.bolt, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TEGA AI',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                // Removed sidebar New Chat button
              ],
            ),
          ),
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          Expanded(
            child: _conversations.isEmpty
                ? Center(
                    child: Text(
                      'No conversations yet',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    itemBuilder: (context, i) {
                      final c = _conversations[i];
                      final selected = identical(c, _active);
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: const Color(0xFFEEF2FF),
                        leading: const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF6B7280),
                          size: 18,
                        ),
                        title: Text(
                          c.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 13,
                          ),
                        ),
                        onTap: () => setState(() => _active = c),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFF9CA3AF),
                            size: 18,
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
                          },
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
  Widget _buildTopBar(BuildContext context, bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          // Model selector (visual only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  _model,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // Chat messages
  Widget _buildChatArea() {
    if (_active == null) {
      return Center(
        child: Text(
          'Start a new chat to begin',
          style: TextStyle(color: Colors.black.withOpacity(0.6)),
        ),
      );
    }
    return ListView.builder(
      controller: _chatScroll,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF6B5FFF) : const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUser
                    ? const Color(0xFF6B5FFF)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              msg.content,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF111827),
                fontSize: 14,
                height: 1.4,
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 6,
              style: const TextStyle(color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Message TEGA AI...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF7F8FC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6B5FFF)),
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isSending ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5FFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.send_rounded, size: 18),
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
