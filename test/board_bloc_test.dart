import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_workspace/features/board/domain/entities/board_column.dart';
import 'package:kanban_workspace/features/board/domain/entities/kanban_task.dart';
import 'package:kanban_workspace/features/board/domain/repositories/board_repository.dart';
import 'package:kanban_workspace/features/board/presentation/bloc/board_bloc.dart';

class _FakeBoardRepository implements BoardRepository {
  @override
  List<BoardColumn> get initialColumns => [
    const BoardColumn(id: 'a', title: 'A', color: 0, tasks: []),
    BoardColumn(
      id: 'b',
      title: 'B',
      color: 0,
      tasks: [
        KanbanTask(
          id: 'task-1',
          title: 'Task',
          description: '',
          assignee: 'AK',
          priority: TaskPriority.medium,
          dueDate: DateTime.utc(2026, 10, 23),
          labels: [],
        ),
      ],
    ),
  ];

  void Function(Map<String, dynamic>)? onMessage;
  String? sentOperationId;

  @override
  Future<void> connect(
    String endpoint,
    void Function(Map<String, dynamic>) onMessage,
  ) async {
    this.onMessage = onMessage;
  }

  @override
  Future<void> createTask(
    BoardColumn column,
    Map<String, String> task, {
    required String operationId,
  }) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> moveTask({
    required String taskId,
    required String operationId,
    required String sourceColumnId,
    required String targetColumnId,
    required int targetIndex,
  }) async {
    sentOperationId = operationId;
  }
}

void main() {
  test('optimistic move rolls back when the server rejects it', () async {
    final repository = _FakeBoardRepository();
    final bloc = BoardBloc(repository);
    final initialColumns = bloc.state.columns;
    final connected = expectLater(
      bloc.stream,
      emitsThrough(
        predicate<BoardState>(
          (state) => state.connection == BoardConnection.connected,
        ),
      ),
    );
    bloc.add(const BoardEndpointChanged('ws://example.test'));
    await connected;
    final moveObserved = expectLater(
      bloc.stream,
      emitsThrough(
        predicate<BoardState>(
          (state) =>
              state.columns[0].tasks.single.id == 'task-1' &&
              state.columns[0].tasks.single.pending,
        ),
      ),
    );
    bloc.add(
      const TaskMoved(
        taskId: 'task-1',
        sourceColumnId: 'b',
        targetColumnId: 'a',
        targetIndex: 0,
        operationId: 'move-1',
      ),
    );
    await moveObserved;
    expect(repository.sentOperationId, 'move-1');

    final rollbackObserved = expectLater(
      bloc.stream,
      emitsThrough(
        predicate<BoardState>(
          (state) =>
              state.columns[1].tasks.single.id == 'task-1' &&
              !state.columns[1].tasks.single.pending &&
              state.error == 'Move denied',
        ),
      ),
    );
    repository.onMessage?.call({
      'type': 'operation.rejected',
      'operation_id': 'move-1',
      'reason': 'Move denied',
    });
    await rollbackObserved;
    expect(bloc.state.columns[0].tasks, isEmpty);
    expect(bloc.state.columns[1].tasks.single.id, 'task-1');
    expect(initialColumns[1].tasks.single.id, 'task-1');
    await bloc.close();
  });
}
