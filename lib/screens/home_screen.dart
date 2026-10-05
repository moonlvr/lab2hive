import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart' show taskBoxName;
import '../models/task.dart';
import '../utils/date_format.dart';
import '../widgets/task_form_dialog.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Task List'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _clearAll(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        tooltip: 'Add school task',
        child: const Icon(Icons.add),
      ),
      // ---------- READ ----------
      // Rebuilds automatically whenever the box changes (add / edit / delete).
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: _box.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) return const _EmptyState();

          // Sorted by due date (earliest first)
          final tasks = box.values.toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          final doneCount = tasks.where((t) => t.isDone).length;

          return Column(
            children: [
              _SummaryBanner(done: doneCount, total: tasks.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 90),
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
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Info lines shown under the title (only if filled in)
    final details = <Widget>[
      _InfoRow(icon: Icons.event, text: 'Due: ${formatDate(task.date)}'),
      if (task.subject.isNotEmpty)
        _InfoRow(icon: Icons.menu_book_outlined, text: task.subject),
      if (task.taskType.isNotEmpty)
        _InfoRow(icon: Icons.assignment_outlined, text: task.taskType),
      if (task.description.isNotEmpty)
        _InfoRow(icon: Icons.description_outlined, text: task.description),
      if (task.professor.isNotEmpty)
        _InfoRow(icon: Icons.person_outline, text: task.professor),
      if (task.submission.isNotEmpty)
        _InfoRow(icon: Icons.link, text: task.submission),
      if (task.notes.isNotEmpty)
        _InfoRow(icon: Icons.sticky_note_2_outlined, text: task.notes),
    ];

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: onTap,
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => onToggle(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? scheme.outline : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details,
          ),
        ),
        trailing: Icon(Icons.edit_outlined, color: scheme.outline),
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
          Text('Tap + to add an assignment, quiz or lab',
              style: TextStyle(color: scheme.outline)),
        ],
      ),
    );
  }
}

/// Green banner at the top showing how many tasks are completed.
class _SummaryBanner extends StatelessWidget {
  final int done;
  final int total;

  const _SummaryBanner({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt, color: scheme.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done of $total tasks done',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}