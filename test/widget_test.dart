import 'package:flutter_test/flutter_test.dart';
import 'package:lab2hive/models/task.dart';

void main() {
  test('Task defaults to not done', () {
    final task = Task(title: 'Sample', date: DateTime(2026, 10, 5));
    expect(task.title, 'Sample');
    expect(task.isDone, false);
  });
}