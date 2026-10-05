import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/date_format.dart';

/// Your subjects (3IT-B). Tap a chip to fill the Subject field quickly.
const List<String> kSubjects = [
  'CCS109',
  'CCS111',
  'ITP103',
  'ITP104',
  'ITP107',
  'ITEW3',
];

/// Dialog used for both adding a new task and editing an existing one.
/// Returns a [Task] (not yet saved) when the user taps Save, or null on cancel.
class TaskFormDialog extends StatefulWidget {
  final Task? existing;

  const TaskFormDialog({super.key, this.existing});

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // 7 text fields
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _subjectController;
  late final TextEditingController _typeController;
  late final TextEditingController _professorController;
  late final TextEditingController _submissionController;
  late final TextEditingController _notesController;

  late DateTime _date;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _subjectController = TextEditingController(text: t?.subject ?? '');
    _typeController = TextEditingController(text: t?.taskType ?? '');
    _professorController = TextEditingController(text: t?.professor ?? '');
    _submissionController = TextEditingController(text: t?.submission ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _date = t?.date ?? DateTime.now();

    // Rebuild so the subject chips highlight while typing
    _subjectController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _typeController.dispose();
    _professorController.dispose();
    _submissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select due date',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    // Validation: title cannot be empty
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Task(
        title: _titleController.text.trim(),
        date: _date,
        isDone: widget.existing?.isDone ?? false,
        description: _descriptionController.text.trim(),
        subject: _subjectController.text.trim(),
        taskType: _typeController.text.trim(),
        professor: _professorController.text.trim(),
        submission: _submissionController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  /// Small helper so every text field looks the same.
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.sentences,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: capitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit School Task' : 'New School Task'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  controller: _titleController,
                  label: 'Task title *',
                  hint: 'e.g. Finals Laboratory 2',
                  icon: Icons.edit_note,
                  autofocus: true,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Task title cannot be empty'
                      : null,
                ),
                _field(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'What needs to be done?',
                  icon: Icons.description_outlined,
                  maxLines: 2,
                ),
                _field(
                  controller: _subjectController,
                  label: 'Subject',
                  hint: 'e.g. ITP107',
                  icon: Icons.menu_book_outlined,
                  capitalization: TextCapitalization.characters,
                ),
                // Quick-pick chips for the subject field
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final s in kSubjects)
                        ChoiceChip(
                          label: Text(s),
                          selected: _subjectController.text.trim() == s,
                          onSelected: (_) => _subjectController.text = s,
                        ),
                    ],
                  ),
                ),
                _field(
                  controller: _typeController,
                  label: 'Task type',
                  hint: 'Assignment, Quiz, Laboratory, Project...',
                  icon: Icons.assignment_outlined,
                ),
                _field(
                  controller: _professorController,
                  label: 'Professor',
                  hint: 'Name of instructor',
                  icon: Icons.person_outline,
                  capitalization: TextCapitalization.words,
                ),
                _field(
                  controller: _submissionController,
                  label: 'Submission link / platform',
                  hint: 'e.g. Google Classroom, GitHub link',
                  icon: Icons.link,
                  keyboardType: TextInputType.url,
                  capitalization: TextCapitalization.none,
                ),
                _field(
                  controller: _notesController,
                  label: 'Notes',
                  icon: Icons.sticky_note_2_outlined,
                  maxLines: 2,
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(formatDate(_date)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}