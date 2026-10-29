import 'package:equatable/equatable.dart';

import 'kanban_task.dart';

class BoardColumn extends Equatable {
  const BoardColumn({
    required this.id,
    required this.title,
    required this.color,
    required this.tasks,
  });

  final String id;
  final String title;
  final int color;
  final List<KanbanTask> tasks;

  BoardColumn copyWith({String? title, List<KanbanTask>? tasks}) {
    return BoardColumn(
      id: id,
      title: title ?? this.title,
      color: color,
      tasks: tasks ?? this.tasks,
    );
  }

  @override
  List<Object?> get props => [id, title, color, tasks];
}
