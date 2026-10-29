part of 'board_bloc.dart';

sealed class BoardEvent extends Equatable {
  const BoardEvent();

  @override
  List<Object?> get props => [];
}

final class BoardStarted extends BoardEvent {
  const BoardStarted();
}

final class BoardEndpointChanged extends BoardEvent {
  const BoardEndpointChanged(this.endpoint);
  final String endpoint;

  @override
  List<Object?> get props => [endpoint];
}

final class TaskMoved extends BoardEvent {
  const TaskMoved({
    required this.taskId,
    required this.sourceColumnId,
    required this.targetColumnId,
    required this.targetIndex,
    required this.operationId,
  });

  final String taskId;
  final String sourceColumnId;
  final String targetColumnId;
  final int targetIndex;
  final String operationId;

  @override
  List<Object?> get props => [
    taskId,
    sourceColumnId,
    targetColumnId,
    targetIndex,
    operationId,
  ];
}

final class TaskMoveAccepted extends BoardEvent {
  const TaskMoveAccepted(this.operationId);
  final String operationId;

  @override
  List<Object?> get props => [operationId];
}

final class TaskMoveRejected extends BoardEvent {
  const TaskMoveRejected(this.operationId, this.reason);
  final String operationId;
  final String reason;

  @override
  List<Object?> get props => [operationId, reason];
}

final class TaskCreated extends BoardEvent {
  const TaskCreated({
    required this.columnId,
    required this.title,
    required this.description,
    required this.assignee,
    required this.priority,
    required this.dueDate,
    required this.labels,
  });

  final String columnId;
  final String title;
  final String description;
  final String assignee;
  final TaskPriority priority;
  final DateTime dueDate;
  final List<String> labels;

  @override
  List<Object?> get props => [
    columnId,
    title,
    description,
    assignee,
    priority,
    dueDate,
    labels,
  ];
}

final class RemoteBoardMessageReceived extends BoardEvent {
  const RemoteBoardMessageReceived(this.message);
  final Map<String, dynamic> message;

  @override
  List<Object?> get props => [message];
}
