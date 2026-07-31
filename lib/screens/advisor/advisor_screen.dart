import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/smartwatch_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/glass_card.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    'Are my current medications safe together?',
    'What should I do if I get a headache?',
    'Can you explain my blood pressure reading?',
    'Suggest a heart-healthy diet plan',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<ChatProvider>(context, listen: false).loadUserSessions(user.id);
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? promptText]) {
    final text = promptText ?? _textController.text;
    if (text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final medProvider = Provider.of<MedicationProvider>(context, listen: false);
    final watchProvider = Provider.of<SmartwatchProvider>(context, listen: false);

    final user = authProvider.currentUser;
    final profile = profileProvider.profile;

    if (user != null && profile != null) {
      _textController.clear();
      chatProvider.sendMessage(
        userText: text,
        userId: user.id,
        profile: profile,
        activeMeds: medProvider.activeMedications,
        currentVitals: watchProvider.currentReading,
      );
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id ?? '';

    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat History Sessions', style: AppTypography.titleLarge),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New Health Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  chatProvider.createNewSession(userId);
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: chatProvider.sessions.length,
                  itemBuilder: (context, index) {
                    final s = chatProvider.sessions[index];
                    final isSelected = chatProvider.currentSession?.id == s.id;
                    return ListTile(
                      title: Text(s.title, style: AppTypography.titleSmall),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        onPressed: () => chatProvider.deleteSession(s.id, userId),
                      ),
                      onTap: () {
                        chatProvider.selectSession(s.id, userId);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.history, color: AppColors.primary),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MediCore Claude AI Advisor', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
                        Text('Powered by Anthropic Claude 3.5 Sonnet • Real-time clinical context', style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
                if (!chatProvider.hasApiKey)
                  TextButton.icon(
                    icon: const Icon(Icons.key, color: AppColors.warning, size: 16),
                    label: const Text('API Key Required', style: TextStyle(color: AppColors.warning)),
                    onPressed: () => context.go('/settings'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Messages Stream List
            Expanded(
              child: chatProvider.messages.isEmpty
                  ? Center(child: Text('Start your consultation...', style: AppTypography.bodyMedium))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatProvider.messages[index];
                        return ChatBubble(message: msg);
                      },
                    ),
            ),

            if (chatProvider.isTyping) const TypingIndicator(),

            // Quick Suggestion Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ActionChip(
                      label: Text(prompt, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                      backgroundColor: AppColors.cardBg,
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Input Bar
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Ask Claude AI about your symptoms, medications, or lab results...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
