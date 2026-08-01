import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/timeline_tile.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedType = 'All';

  void _showAddEventModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String type = 'custom';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log Health Event', style: AppTypography.displaySmall.copyWith(fontSize: 20)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Event Title (e.g. Blood Test Result)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Event Category'),
                    dropdownColor: AppColors.surface,
                    items: ['medication', 'scan', 'vitals', 'appointment', 'document', 'custom']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                        .toList(),
                    onChanged: (val) => setModalState(() => type = val ?? 'custom'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description & Clinical Notes'),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    text: 'Save Event to Timeline',
                    width: double.infinity,
                    onPressed: () async {
                      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                      if (user != null && titleController.text.trim().isNotEmpty) {
                        await Provider.of<HistoryProvider>(context, listen: false).addEvent(
                          userId: user.id,
                          type: type,
                          title: titleController.text,
                          description: descController.text,
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<HistoryProvider>(context);
    final allEvents = historyProvider.events;

    final events = _selectedType == 'All'
        ? allEvents
        : allEvents.where((e) => e.type == _selectedType.toLowerCase()).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Timeline & Logs', style: AppTypography.displaySmall),
                    Text('Chronological electronic health record history & automated entries', style: AppTypography.bodySmall),
                  ],
                ),
                GradientButton(
                  text: 'Log Event',
                  icon: Icons.add,
                  onPressed: _showAddEventModal,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'medication', 'scan', 'vitals', 'appointment', 'document', 'custom'].map((t) {
                  final isSelected = _selectedType == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.toUpperCase()),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.cardBg,
                      labelStyle: TextStyle(color: isSelected ? Colors.black : AppColors.textPrimary),
                      onSelected: (_) => setState(() => _selectedType = t),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: events.isEmpty
                  ? const EmptyState(
                      icon: Icons.history,
                      title: 'No Timeline Events',
                      description: 'Events logged from prescriptions, scans, or manual entries will appear here.',
                    )
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return TimelineTile(
                          event: event,
                          isLast: index == events.length - 1,
                          onDelete: () => historyProvider.deleteEvent(event.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
