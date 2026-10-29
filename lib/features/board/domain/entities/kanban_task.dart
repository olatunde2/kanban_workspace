import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

class KanbanTask extends Equatable {
  const KanbanTask({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.priority,
    required this.dueDate,
    required this.labels,
    this.pending = false,
  });

  final String id;
  final String title;
  final String description;
  final String assignee;
  final TaskPriority priority;
  final DateTime dueDate;
  final List<String> labels;
  final bool pending;

  KanbanTask copyWith({
    String? title,
    String? description,
    String? assignee,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String>? labels,
    bool? pending,
  }) {
    return KanbanTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      labels: labels ?? this.labels,
      pending: pending ?? this.pending,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    assignee,
    priority,
    dueDate,
    labels,
    pending,
  ];
}
