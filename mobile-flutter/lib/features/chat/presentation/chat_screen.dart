import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../discovery/models/match_profile.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final MatchProfile? matchProfile;

  const ChatScreen({
    super.key,
    required this.matchId,
    this.matchProfile,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final ChatNotifier _chatNotifier;

  @override
  void initState() {
    super.initState();
    _chatNotifier = ref.read(chatProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatNotifier.setActiveMatch(widget.matchId);
    });
  }

  @override
  void dispose() {
    _chatNotifier.leaveChat();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSafetyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.block, color: AppColors.roseGlow),
                title: Text('Block Candidate', style: AppTypography.titleMedium.copyWith(color: AppColors.roseGlow)),
                onTap: () {
                  Navigator.pop(context);
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Candidate blocked successfully.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.roseGlow),
                title: Text('Report Suspicious Activity', style: AppTypography.titleMedium.copyWith(color: AppColors.roseGlow)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report sent to Trust & Safety Sentinel.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.roseGlow,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    final chatState = ref.watch(chatProvider);
    final currentUserId = ref.watch(authProvider).user?.id ?? '';
    final messages = chatState.activeMessages;
    final partnerName = widget.matchProfile?.name ?? 'Candidate';

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.champagneGold),
          onPressed: () => context.pop(),
        ),
        title: partnerName,
        actions: [
          const Center(child: VerifiedBadge(size: 16)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.champagneGold),
            onPressed: _showSafetyOptions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (messages.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No messages yet. Say hello to $partnerName.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),

            // Messages View
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMine = msg.senderId == currentUserId;
                  return _buildMessageRow(msg, isMine);
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.darkSlate,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: AppTypography.bodyMedium,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.darkCardElevated,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: AppColors.obsidianBlack,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage msg, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMine ? AppColors.champagneGold : AppColors.darkSlate,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: isMine ? AppColors.champagneGold : AppColors.borderGold.withOpacity(0.3),
            width: 0.8,
          ),
        ),
        child: Text(
          msg.text,
          style: AppTypography.bodyMedium.copyWith(
            color: isMine ? AppColors.obsidianBlack : AppColors.textPure,
            fontWeight: isMine ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
