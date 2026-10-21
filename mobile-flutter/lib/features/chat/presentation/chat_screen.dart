import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../../core/widgets/knot_image.dart';
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
        centerTitle: false,
        titleWidget: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: KnotImage(
                imageUrl: widget.matchProfile?.photos.isNotEmpty == true
                    ? widget.matchProfile!.photos.first
                    : null,
                width: 36,
                height: 36,
                isCircle: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    partnerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: const [
                      Icon(Icons.verified, size: 12, color: Color(0xFF10B981)),
                      SizedBox(width: 3),
                      Text(
                        'Verified Real Human',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF9DABBF)),
            onPressed: _showSafetyOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (chatState.hasReachedMessageLimit)
                  GestureDetector(
                    onTap: () => context.push('/paywall'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppColors.roseGlow.withOpacity(0.15),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_clock, size: 16, color: AppColors.roseGlow),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Free conversation limit reached. Upgrade to continue.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.roseGlow,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.champagneGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'UPGRADE ✨',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

                // Input Bar or Limit Reached Bar
                if (chatState.hasReachedMessageLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.darkSlate,
                      border: Border(top: BorderSide(color: AppColors.borderGold)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.champagneGold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Free tier conversation limit reached.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.champagneGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => context.push('/paywall'),
                          child: const Text(
                            'UPGRADE',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.roseGlowGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryRose.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
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
          if (chatState.showUpgradeFlier)
            _buildUpgradeFlierModal(context, ref.read(chatProvider.notifier)),
        ],
      ),
    );
  }

  Widget _buildUpgradeFlierModal(BuildContext context, ChatNotifier notifier) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSubtle),
                    onPressed: () => notifier.dismissUpgradeFlier(),
                  ),
                ),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [AppColors.champagneGold, AppColors.deepGold],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.champagneGold.withOpacity(0.4),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 34, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.champagneGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Text(
                    'CONVERSATION LIMIT REACHED',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.champagneGold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upgrade to Continue Chatting',
                  style: AppTypography.displayMedium.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Free members can message one match. Upgrade your membership tier now to unlock unlimited intentional messaging and vows.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlate,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildPerkRow('Unlimited intentional messages with matches'),
                      const SizedBox(height: 8),
                      _buildPerkRow('15 to 100 AI-Curated verified matches daily'),
                      const SizedBox(height: 8),
                      _buildPerkRow('Priority delivery & verified status'),
                      const SizedBox(height: 8),
                      _buildPerkRow('Full psychological compatibility insights'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GoldButton(
                  text: 'Upgrade Now ✨',
                  onPressed: () {
                    notifier.dismissUpgradeFlier();
                    context.push('/paywall');
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => notifier.dismissUpgradeFlier(),
                  child: Text('Maybe Later', style: AppTypography.bodySmall.copyWith(color: AppColors.textSubtle)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerkRow(String perk) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.champagneGold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            perk,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPure, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow(ChatMessage msg, bool isMine) {
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
    final partnerPhoto = widget.matchProfile?.photos.isNotEmpty == true
        ? widget.matchProfile!.photos.first
        : null;

    if (isMine) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4C1D95), // Deep royal purple / violet bubble
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4C1D95).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Candidate circular avatar
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                child: KnotImage(
                  imageUrl: partnerPhoto,
                  width: 28,
                  height: 28,
                  isCircle: true,
                ),
              ),
              // Dark slate incoming message bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182028), // Dark slate container
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: const Color(0xFF28313E),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.text,
                        style: const TextStyle(
                          color: Color(0xFFD1D5DC), // Soft pearl grey / off-white
                          fontSize: 14.5,
                          fontWeight: FontWeight.normal,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
