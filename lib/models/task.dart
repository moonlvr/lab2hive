import 'package:hive/hive.dart';

part 'task.g.dart';

/// A single school task stored in the Hive box.
@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date; // due date

  @HiveField(2)
  bool isDone;

  @HiveField(3)
  String description;

  @HiveField(4)
  String subject; // e.g. ITP107

  @HiveField(5)
  String taskType; // e.g. Laboratory, Quiz, Assignment

  @HiveField(6)
  String professor;

  @HiveField(7)
  String submission; // link or platform (e.g. Google Classroom)

  @HiveField(8)
  String notes;

  Task({
    required this.title,
    required this.date,
    this.isDone = false,
    this.description = '',
    this.subject = '',
    this.taskType = '',
    this.professor = '',
    this.submission = '',
    this.notes = '',
  });

  /// Returns an unsaved copy (used for the Undo after deleting).
  Task clone() => Task(
        title: title,
        date: date,
        isDone: isDone,
        description: description,
        subject: subject,
        taskType: taskType,
        professor: professor,
        submission: submission,
        notes: notes,
      );

  /// Copies the editable values from another task (used when editing).
  void updateFrom(Task other) {
    title = other.title;
    date = other.date;
    description = other.description;
    subject = other.subject;
    taskType = other.taskType;
    professor = other.professor;
    submission = other.submission;
    notes = other.notes;
  }
}