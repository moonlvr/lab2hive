import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart' show taskBoxName;
import '../models/task.dart';
import '../utils/date_format.dart';
import '../widgets/task_form_dialog.dart';

const List<String> _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Box<Task> get _box => Hive.box<Task>(taskBoxName);

  // ---------- CREATE ----------
  Future<void> _addTask(BuildContext context) async {
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => const TaskFormDialog(),
    );
    if (task != null) await _box.add(task);
  }

  // ---------- UPDATE ----------
  Future<void> _editTask(BuildContext context, dynamic key) async {
    final current = _box.get(key); // .get
    if (current == null) return;

    final updated = await showDialog<Task>(
      context: context,
      builder: (_) => TaskFormDialog(existing: current),
    );
    if (updated != null) {
      await _box.put(key, updated); // .put (overwrites the same key)
    }
  }

  Future<void> _toggleDone(dynamic key) async {
    final current = _box.get(key); // .get
    if (current == null) return;
    current.isDone = !current.isDone;
    await _box.put(key, current); // .put
  }

  // ---------- DELETE ----------
  Future<void> _deleteTask(BuildContext context, dynamic key) async {
    final backup = _box.get(key)?.clone(); // .get (for Undo)
    final index = _box.keys.toList().indexOf(key);
    if (backup == null || index < 0) return;

    await _box.deleteAt(index); // .deleteAt

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${backup.title}" deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => _box.put(key, backup),
          ),
        ),
      );
  }

  // ---------- CLEAR ALL ----------
  Future<void> _clearAll(BuildContext context) async {
    if (_box.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all tasks?'),
        content: const Text('This will delete every task in your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirm == true) await _box.clear(); // .clear
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // white status bar icons
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addTask(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
        ),
        // ---------- READ ----------
        // Rebuilds automatically whenever the box changes (add / edit / delete).
        body: ValueListenableBuilder<Box<Task>>(
          valueListenable: _box.listenable(),
          builder: (context, box, _) {
            // Unfinished first (by due date), finished tasks at the bottom
            final tasks = box.values.toList()
              ..sort((a, b) {
                if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
                return a.date.compareTo(b.date);
              });
            final doneCount = tasks.where((t) => t.isDone).length;

            return Column(
              children: [
                _Header(
                  done: doneCount,
                  total: tasks.length,
                  onClear: () => _clearAll(context),
                ),
                Expanded(
                  child: tasks.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 10, bottom: 100),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final key = task.key;
                            return Dismissible(
                              key: ValueKey(key),
                              direction: DismissDirection.endToStart,
                              background: const _DeleteBackground(),
                              onDismissed: (_) => _deleteTask(context, key),
                              child: _TaskCard(
                                task: task,
                                onTap: () => _editTask(context, key),
                                onToggle: () => _toggleDone(key),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =====================================================================
// HEADER
// =====================================================================
class _Header extends StatelessWidget {
  final int done;
  final int total;
  final VoidCallback onClear;

  const _Header({
    required this.done,
    required this.total,
    required this.onClear,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pending = total - done;
    final progress = total == 0 ? 0.0 : done / total;
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + title + clear button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_greeting 👋',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'My School Tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Clear all',
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_sweep_outlined,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Today's date
              Row(
                children: [
                  const Icon(Icons.calendar_month,
                      size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    '${_weekdays[now.weekday - 1]}, ${formatDate(now)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Counters
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    _StatTile(label: 'Total', value: total),
                    const SizedBox(width: 10),
                    _StatTile(label: 'Done', value: done),
                    const SizedBox(width: 10),
                    _StatTile(label: 'Pending', value: pending),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Progress bar
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// TASK CARD
// =====================================================================
class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  /// Returns (label, color) depending on the due date / done state.
  (String, Color) _status(ColorScheme scheme) {
    if (task.isDone) return ('Done', Colors.grey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(task.date.year, task.date.month, task.date.day);
    if (due.isBefore(today)) return ('Overdue', scheme.error);
    if (due == today) return ('Due today', Colors.orange.shade800);
    return ('Upcoming', scheme.primary);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = _status(scheme);

    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored stripe on the left
            Container(width: 6, color: statusColor),
            Expanded(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                onTap: onTap,
                leading: Checkbox(
                  value: task.isDone,
                  onChanged: (_) => onToggle(),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    decoration:
                        task.isDone ? TextDecoration.lineThrough : null,
                    color: task.isDone ? scheme.outline : null,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Pill(text: statusLabel, color: statusColor),
                          if (task.subject.isNotEmpty)
                            _Pill(text: task.subject, color: scheme.primary),
                          if (task.taskType.isNotEmpty)
                            _Pill(text: task.taskType, color: Colors.blueGrey),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.event,
                        text: 'Due: ${formatDate(task.date)}',
                      ),
                      if (task.description.isNotEmpty)
                        _InfoRow(
                            icon: Icons.description_outlined,
                            text: task.description),
                      if (task.professor.isNotEmpty)
                        _InfoRow(
                            icon: Icons.person_outline, text: task.professor),
                      if (task.submission.isNotEmpty)
                        _InfoRow(icon: Icons.link, text: task.submission),
                      if (task.notes.isNotEmpty)
                        _InfoRow(
                            icon: Icons.sticky_note_2_outlined,
                            text: task.notes),
                    ],
                  ),
                ),
                trailing: Icon(Icons.edit_outlined, color: scheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small rounded tag (status, subject, task type).
class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One line with a small icon and text, used inside each task card.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: scheme.primary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.only(right: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.delete, color: scheme.onError),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined,
              size: 80, color: scheme.primary.withAlpha(120)),
          const SizedBox(height: 12),
          Text('No school tasks yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Tap "Add Task" to add an assignment, quiz or lab',
              style: TextStyle(color: scheme.outline)),
        ],
      ),
    );
  }
}