import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/board_column.dart';
import '../../domain/entities/kanban_task.dart';
import '../../domain/repositories/board_repository.dart';

part 'board_event.dart';
part 'board_state.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc(this._repository)
    : super(BoardState(columns: _repository.initialColumns)) {
    on<BoardStarted>(_onStarted);
    on<BoardEndpointChanged>(_onEndpointChanged);
    on<TaskMoved>(_onTaskMoved);
    on<TaskMoveAccepted>(_onTaskMoveAccepted);
    on<TaskMoveRejected>(_onTaskMoveRejected);
    on<TaskCreated>(_onTaskCreated);
    on<RemoteBoardMessageReceived>(_onRemoteMessage);
  }

  final BoardRepository _repository;
  static const _uuid = Uuid();
  final Map<String, List<BoardColumn>> _snapshots = {};
  final Map<String, String> _pendingTaskCreates = {};

  Future<void> _onStarted(BoardStarted event, Emitter<BoardState> emit) async {
    await _connect(state.endpoint, emit);
  }

  Future<void> _onEndpointChanged(
    BoardEndpointChanged event,
    Emitter<BoardState> emit,
  ) async {
    final endpoint = event.endpoint.trim();
    emit(state.copyWith(endpoint: endpoint));
    await _connect(endpoint, emit);
  }

  Future<void> _connect(String endpoint, Emitter<BoardState> emit) async {
    await _repository.disconnect();
    if (endpoint.isEmpty) {
      emit(state.copyWith(connection: BoardConnection.local, clearError: true));
      return;
    }
    emit(
      state.copyWith(connection: BoardConnection.connecting, clearError: true),
    );
    try {
      await _repository.connect(
        endpoint,
        (message) => add(RemoteBoardMessageReceived(message)),
      );
      emit(state.copyWith(connection: BoardConnection.connected));
    } catch (error) {
      emit(
        state.copyWith(
          connection: BoardConnection.disconnected,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onTaskMoved(TaskMoved event, Emitter<BoardState> emit) async {
    final before = state.columns;
    final columns = _move(before, event);
    if (columns == null) return;
    _snapshots[event.operationId] = before;
    emit(state.copyWith(columns: columns));
    try {
      await _repository.moveTask(
        taskId: event.taskId,
        operationId: event.operationId,
        sourceColumnId: event.sourceColumnId,
        targetColumnId: event.targetColumnId,
        targetIndex: event.targetIndex,
      );
      if (state.connection != BoardConnection.connected) {
        add(TaskMoveAccepted(event.operationId));
      }
    } catch (error) {
      add(TaskMoveRejected(event.operationId, error.toString()));
    }
  }

  List<BoardColumn>? _move(List<BoardColumn> columns, TaskMoved event) {
    final sourceIndex = columns.indexWhere(
      (column) => column.id == event.sourceColumnId,
    );
    final targetIndex = columns.indexWhere(
      (column) => column.id == event.targetColumnId,
    );
    if (sourceIndex < 0 || targetIndex < 0) return null;
    final sourceTasks = [...columns[sourceIndex].tasks];
    final taskIndex = sourceTasks.indexWhere((task) => task.id == event.taskId);
    if (taskIndex < 0) return null;
    final task = sourceTasks.removeAt(taskIndex);
    final targetTasks = sourceIndex == targetIndex
        ? sourceTasks
        : [...columns[targetIndex].tasks];
    final insertionIndex = event.targetIndex.clamp(0, targetTasks.length);
    targetTasks.insert(insertionIndex, task.copyWith(pending: true));
    final result = [...columns];
    result[sourceIndex] = result[sourceIndex].copyWith(tasks: sourceTasks);
    result[targetIndex] = result[targetIndex].copyWith(tasks: targetTasks);
    return result;
  }

  void _onTaskMoveAccepted(TaskMoveAccepted event, Emitter<BoardState> emit) {
    final snapshot = _snapshots.remove(event.operationId);
    if (snapshot == null) return;
    emit(state.copyWith(columns: _markSettled(state.columns, snapshot)));
  }

  void _onTaskMoveRejected(TaskMoveRejected event, Emitter<BoardState> emit) {
    final snapshot = _snapshots.remove(event.operationId);
    if (snapshot == null) return;
    emit(state.copyWith(columns: snapshot, error: event.reason));
  }

  List<BoardColumn> _markSettled(
    List<BoardColumn> columns,
    List<BoardColumn> snapshot,
  ) {
    final pendingIds = snapshot
        .expand((column) => column.tasks)
        .map((task) => task.id)
        .toSet();
    return columns
        .map(
          (column) => column.copyWith(
            tasks: column.tasks
                .map(
                  (task) => pendingIds.contains(task.id)
                      ? task.copyWith(pending: false)
                      : task,
                )
                .toList(),
          ),
        )
        .toList();
  }

  Future<void> _onTaskCreated(
    TaskCreated event,
    Emitter<BoardState> emit,
  ) async {
    final columnIndex = state.columns.indexWhere(
      (column) => column.id == event.columnId,
    );
    if (columnIndex < 0) return;
    final taskId = _uuid.v4();
    final operationId = _uuid.v4();
    final task = KanbanTask(
      id: taskId,
      title: event.title,
      description: event.description,
      assignee: event.assignee,
      priority: event.priority,
      dueDate: event.dueDate,
      labels: event.labels,
      pending: true,
    );
    final columns = [...state.columns];
    columns[columnIndex] = columns[columnIndex].copyWith(
      tasks: [...columns[columnIndex].tasks, task],
    );
    emit(state.copyWith(columns: columns));
    try {
      if (state.connection == BoardConnection.connected) {
        _pendingTaskCreates[operationId] = taskId;
      }
      await _repository.createTask(columns[columnIndex], {
        'task_id': taskId,
        'title': task.title,
        'description': task.description,
        'assignee': task.assignee,
        'priority': task.priority.name,
        'due_date': task.dueDate.toIso8601String(),
        'labels': task.labels.join(','),
      }, operationId: operationId);
      if (state.connection != BoardConnection.connected) {
        emit(state.copyWith(columns: _settleTask(state.columns, taskId)));
      }
    } catch (error) {
      _pendingTaskCreates.remove(operationId);
      emit(
        state.copyWith(
          columns: _removeTask(state.columns, taskId),
          error: 'Could not create task: $error',
        ),
      );
    }
  }

  void _onRemoteMessage(
    RemoteBoardMessageReceived event,
    Emitter<BoardState> emit,
  ) {
    final operationId = _stringField(event.message, 'operation_id');
    final type = _stringField(event.message, 'type');
    if (type == 'connection.error' || type == 'connection.closed') {
      emit(
        state.copyWith(
          connection: BoardConnection.disconnected,
          error:
              _stringField(event.message, 'reason') ??
              'WebSocket connection was interrupted.',
        ),
      );
      return;
    }
    if (operationId != null && _pendingTaskCreates.containsKey(operationId)) {
      final taskId = _pendingTaskCreates.remove(operationId)!;
      if (type == 'operation.rejected') {
        emit(
          state.copyWith(
            columns: _removeTask(state.columns, taskId),
            error:
                _stringField(event.message, 'reason') ??
                'Server rejected the task.',
          ),
        );
      } else if (type == 'operation.accepted') {
        emit(state.copyWith(columns: _settleTask(state.columns, taskId)));
      }
      return;
    }
    if (operationId != null && _snapshots.containsKey(operationId)) {
      if (type == 'operation.rejected') {
        add(
          TaskMoveRejected(
            operationId,
            _stringField(event.message, 'reason') ??
                'Server rejected the move.',
          ),
        );
      } else if (type == 'operation.accepted') {
        add(TaskMoveAccepted(operationId));
      }
      return;
    }
    if (type == 'task.create') {
      _applyRemoteTaskCreate(event.message, emit);
      return;
    }
    if (type != 'task.move') return;
    final taskId = _stringField(event.message, 'task_id');
    final source = _stringField(event.message, 'source_column_id');
    final target = _stringField(event.message, 'target_column_id');
    final index = event.message['target_index'];
    if (taskId == null || source == null || target == null || index is! int) {
      return;
    }
    final updated = _move(
      state.columns,
      TaskMoved(
        taskId: taskId,
        sourceColumnId: source,
        targetColumnId: target,
        targetIndex: index,
        operationId: operationId ?? _uuid.v4(),
      ),
    );
    if (updated != null) {
      emit(state.copyWith(columns: _settleTask(updated, taskId)));
    }
  }

  void _applyRemoteTaskCreate(
    Map<String, dynamic> message,
    Emitter<BoardState> emit,
  ) {
    final taskId = _stringField(message, 'task_id');
    final columnId = _stringField(message, 'column_id');
    final title = _stringField(message, 'title');
    final description = _stringField(message, 'description');
    final assignee = _stringField(message, 'assignee');
    final priorityName = _stringField(message, 'priority');
    final dueDateValue = _stringField(message, 'due_date');
    final columnIndex = state.columns.indexWhere(
      (column) => column.id == columnId,
    );
    TaskPriority? priority;
    for (final candidate in TaskPriority.values) {
      if (candidate.name == priorityName) priority = candidate;
    }
    final dueDate = dueDateValue == null
        ? null
        : DateTime.tryParse(dueDateValue);
    if (taskId == null ||
        columnIndex < 0 ||
        title == null ||
        description == null ||
        assignee == null ||
        priority == null ||
        dueDate == null) {
      emit(state.copyWith(error: 'Received an invalid task.create message.'));
      return;
    }
    if (state.columns.any(
      (column) => column.tasks.any((task) => task.id == taskId),
    )) {
      return;
    }
    final rawLabels = message['labels'];
    final labels = switch (rawLabels) {
      List<dynamic> values => values.whereType<String>().toList(),
      String value =>
        value
            .split(',')
            .map((label) => label.trim())
            .where((label) => label.isNotEmpty)
            .toList(),
      _ => <String>[],
    };
    final columns = [...state.columns];
    columns[columnIndex] = columns[columnIndex].copyWith(
      tasks: [
        ...columns[columnIndex].tasks,
        KanbanTask(
          id: taskId,
          title: title,
          description: description,
          assignee: assignee,
          priority: priority,
          dueDate: dueDate,
          labels: labels,
        ),
      ],
    );
    emit(state.copyWith(columns: columns));
  }

  String? _stringField(Map<String, dynamic> message, String field) {
    final value = message[field];
    return value is String ? value : null;
  }

  List<BoardColumn> _settleTask(List<BoardColumn> columns, String taskId) {
    return columns
        .map(
          (column) => column.copyWith(
            tasks: column.tasks
                .map(
                  (task) =>
                      task.id == taskId ? task.copyWith(pending: false) : task,
                )
                .toList(),
          ),
        )
        .toList();
  }

  List<BoardColumn> _removeTask(List<BoardColumn> columns, String taskId) {
    return columns
        .map(
          (column) => column.copyWith(
            tasks: column.tasks.where((task) => task.id != taskId).toList(),
          ),
        )
        .toList();
  }

  @override
  Future<void> close() async {
    await _repository.disconnect();
    await super.close();
  }
}
