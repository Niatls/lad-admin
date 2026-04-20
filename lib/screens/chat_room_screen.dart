import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lad_admin/providers/chat_provider.dart';
import 'package:lad_admin/models/chat_message.dart';
import 'package:lad_admin/models/chat_session.dart';
import 'package:lad_admin/widgets/chat/voice_message_player.dart';

import 'package:lad_admin/widgets/chat/voice_recorder_overlay.dart';
import 'package:lad_admin/widgets/chat/reply_preview.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:lad_admin/widgets/chat/voice_call_overlay.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const ChatRoomScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ItemScrollController _itemScrollController = ItemScrollController();


  
  ChatMessage? _replyTarget;
  int? _editingMessageId;
  bool _isRecording = false;
  VoiceDraft? _voiceDraft;
  final Set<int> _selectedMessageIds = {};
  bool _isSelectionMode = false;
  String? _activeVoiceToken;
  String? _visitorName;



  void _scrollToBottom() {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: 10000,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _jumpToMessage(int messageId, List<ChatMessage> messages) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final notifier = ref.read(chatMessagesProvider(widget.sessionId).notifier);
    bool success;

    if (_editingMessageId != null) {
      success = await notifier.editMessage(_editingMessageId!, text);
      setState(() => _editingMessageId = null);
    } else {
      success = await notifier.sendMessage(text, replyToId: _replyTarget?.id);
      setState(() => _replyTarget = null);
    }

    _controller.clear();
    
    if (success) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при отправке сообщения')),
        );
      }
    }
  }

  Future<void> _handleVoiceSave(String path, int durationMs, String transcript) async {
    setState(() {
      _isRecording = false;
      _voiceDraft = VoiceDraft(path: path, durationMs: durationMs, transcript: transcript);
    });
  }

  Future<void> _sendVoiceDraft() async {
    if (_voiceDraft == null) return;
    
    final success = await ref.read(chatMessagesProvider(widget.sessionId).notifier).sendVoiceMessage(
      _voiceDraft!.path, 
      _voiceDraft!.durationMs, 
      transcript: _voiceDraft!.transcript,
      replyToId: _replyTarget?.id,
    );
    
    if (success) {
      setState(() {
        _voiceDraft = null;
        _replyTarget = null;
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _cancelVoiceDraft() {
    setState(() {
      _voiceDraft = null;
    });
  }

  void _onReply(ChatMessage message) {
    setState(() {
      _replyTarget = message;
      _editingMessageId = null;
    });
  }

  Future<void> _onStartVoiceCall() async {
    final notifier = ref.read(chatMessagesProvider(widget.sessionId).notifier);
    final token = await notifier.generateVoiceToken();
    if (token != null) {
      if (mounted) {
        setState(() {
          _activeVoiceToken = token;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate voice token')),
        );
      }
    }
  }

  void _onEdit(ChatMessage message) {

    setState(() {
      _editingMessageId = message.id;
      _replyTarget = null;
      _controller.text = message.content;
    });
  }

  void _toggleSelection(int messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(messageId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _handleDeleteSelected() async {
    if (_selectedMessageIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить ${_selectedMessageIds.length} сообщ.?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(chatMessagesProvider(widget.sessionId).notifier)
          .deleteMessages(_selectedMessageIds.toList());
      if (success) _clearSelection();
    }
  }


  Future<void> _onDelete(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сообщение?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(chatMessagesProvider(widget.sessionId).notifier).deleteMessage(message.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider(widget.sessionId));
    final sessionState = ref.watch(sessionDetailsProvider(widget.sessionId));

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: _isSelectionMode 
          ? Text('${_selectedMessageIds.length} выбрано')
          : sessionState.when(
              data: (s) => Text(s.visitorName ?? 'Чат #${s.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              loading: () => const Text('Чат...', style: TextStyle(fontWeight: FontWeight.bold)),
              error: (_, __) => const Text('Чат', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        backgroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: _isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
          : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _handleDeleteSelected,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                // Show Voice Events sidebar/dialog
              },
            ),
          ]
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: messagesState.when(
                  data: (messages) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    
                    return ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,

                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final replyTo = message.replyToId != null 
                            ? messages.where((m) => m.id == message.replyToId).firstOrNull 
                            : null;

                        return _MessageBubble(
                          message: message,
                          replyTo: replyTo,
                          isSelected: _selectedMessageIds.contains(message.id),
                          onReply: () => _onReply(message),
                          onEdit: message.isFromAdmin ? () => _onEdit(message) : null,
                          onDelete: message.isFromAdmin ? () => _onDelete(message) : null,
                          onToggleSelection: () => _toggleSelection(message.id),
                          onJumpToReply: (id) => _jumpToMessage(id, messages),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2D4A3E))),
                  error: (err, stack) => Center(child: Text('Ошибка: $err')),
                ),
              ),
              if (_replyTarget != null)
                ReplyPreview(
                  message: _replyTarget!,
                  onCancel: () => setState(() => _replyTarget = null),
                ),
              if (_editingMessageId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFF5F0E8),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Редактирование', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _editingMessageId = null;
                            _controller.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              if (_voiceDraft != null)
                _buildVoiceDraftArea()
              else if (_isRecording)
                _buildRecorderArea()
              else
                _buildInputArea(),
            ],
          ),
          if (_activeVoiceToken != null)
            Positioned.fill(
              child: VoiceCallOverlay(
                token: _activeVoiceToken!,
                participantName: sessionState.asData?.value.visitorName ?? 'Посетитель',
                onClose: () => setState(() => _activeVoiceToken = null),
              ),
            ),

        ],
      ),
    );
  }


  Widget _buildRecorderArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: VoiceRecorderOverlay(
          onSave: _handleVoiceSave,
          onCancel: () => setState(() => _isRecording = false),
          isInline: true,
        ),
      ),
    );
  }

  Widget _buildVoiceDraftArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _cancelVoiceDraft,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: Color(0xFF2D4A3E), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Note (${(_voiceDraft!.durationMs / 1000).toStringAsFixed(1)}s)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D4A3E)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendVoiceDraft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: Color(0xFF2D4A3E), shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_voiceDraft!.transcript.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transcript:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(_voiceDraft!.transcript, style: const TextStyle(fontSize: 13, color: Color(0xFF2D4A3E))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Напишите сообщение...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _onStartVoiceCall,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFB5CDB2).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_outlined, color: Color(0xFF2D4A3E), size: 20),
              ),
            ),
            const SizedBox(width: 8),
            ListenableBuilder(

              listenable: _controller,
              builder: (context, _) {
                final hasText = _controller.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: hasText ? _handleSend : () => setState(() => _isRecording = true),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D4A3E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasText ? Icons.send : Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ChatMessage? replyTo;
  final bool isSelected;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onToggleSelection;
  final Function(int) onJumpToReply;

  const _MessageBubble({
    required this.message,
    this.replyTo,
    required this.isSelected,
    required this.onReply,
    this.onEdit,
    this.onDelete,
    required this.onToggleSelection,
    required this.onJumpToReply,
  });



  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isFromAdmin;
    final dateFormat = DateFormat('HH:mm');

    return GestureDetector(
      onTap: onToggleSelection,
      onLongPress: () => _showContextMenu(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected ? const Color(0xFF2D4A3E).withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              final clampedValue = value.clamp(0.0, 1.0);
              return Opacity(
                opacity: clampedValue,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - clampedValue)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF2D4A3E) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(isMe ? 24 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 24),
                    ),
                    border: isMe ? null : Border.all(color: const Color(0xFFB5CDB2).withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (replyTo != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => onJumpToReply(replyTo!.id),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 2, height: 20, color: isMe ? Colors.white70 : const Color(0xFF2D4A3E)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      replyTo!.voiceMetadata != null ? '🎤 Голосовое сообщение' : replyTo!.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMe ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      _buildMessageContent(message, isMe),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(left: isMe ? 0 : 4, right: isMe ? 4 : 0),
                  child: Text(
                    dateFormat.format(message.createdAt).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9, 
                      fontWeight: FontWeight.w800, 
                      letterSpacing: 0.5,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }






  Widget _buildMessageContent(ChatMessage message, bool isMe) {
    final voiceData = message.voiceMetadata;
    if (voiceData != null) {
      return VoiceMessagePlayer(
        metadata: voiceData,
        isFromMe: isMe,
        messageId: message.id,
        sessionId: message.sessionId,
      );
    }

    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : const Color(0xFF2D4A3E),
        fontSize: 16,
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(value: 'reply', child: Row(children: [Icon(Icons.reply), SizedBox(width: 8), Text('Ответить')])),
        const PopupMenuItem(value: 'select', child: Row(children: [Icon(Icons.check_circle_outline), SizedBox(width: 8), Text('Выбрать')])),
        if (message.isFromAdmin && message.voiceMetadata == null)
          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Изменить')])),
        if (message.isFromAdmin)
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Удалить', style: TextStyle(color: Colors.red))])),
      ],
    ).then((value) {
      if (value == 'reply') onReply();
      if (value == 'select') onToggleSelection();
      if (value == 'edit') onEdit?.call();
      if (value == 'delete') onDelete?.call();
    });

  }
}
