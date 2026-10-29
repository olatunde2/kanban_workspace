import '../../domain/entities/board_column.dart';
import '../../domain/entities/kanban_task.dart';
import '../../domain/repositories/board_repository.dart';
import '../datasources/board_remote_data_source.dart';

class BoardRepositoryImpl implements BoardRepository {
  BoardRepositoryImpl(this._remote);

  final BoardRemoteDataSource _remote;
  static final _today = DateTime.now();

  @override
  List<BoardColumn> get initialColumns => [
    BoardColumn(
      id: 'backlog',
      title: 'Backlog',
      color: 0xFF8B8BA7,
      tasks: [
        _task(
          'BD-104',
          'Audit onboarding flow',
          'Review drop-off points and map friction across the first session.',
          'LM',
          TaskPriority.medium,
          1,
          ['Research', 'Product'],
        ),
        _task(
          'BD-108',
          'Competitive landscape',
          'Collect examples of lightweight collaboration tools.',
          'AK',
          TaskPriority.low,
          3,
          ['Strategy'],
        ),
      ],
    ),
    BoardColumn(
      id: 'progress',
      title: 'In progress',
      color: 0xFF5B5BD6,
      tasks: [
        _task(
          'BD-101',
          'Design system refresh',
          'Define the next iteration of our core components.',
          'AK',
          TaskPriority.high,
          0,
          ['Design', 'Q3'],
        ),
        _task(
          'BD-106',
          'Mobile navigation',
          'Explore a more focused navigation model for smaller screens.',
          'JR',
          TaskPriority.medium,
          2,
          ['Mobile'],
        ),
      ],
    ),
    BoardColumn(
      id: 'review',
      title: 'In review',
      color: 0xFFE3A63F,
      tasks: [
        _task(
          'BD-099',
          'Analytics events',
          'Align event naming and validate the tracking plan.',
          'MS',
          TaskPriority.high,
          -1,
          ['Engineering'],
        ),
      ],
    ),
    BoardColumn(
      id: 'done',
      title: 'Done',
      color: 0xFF42A88A,
      tasks: [
        _task(
          'BD-095',
          'Kick-off workshop',
          'Capture team goals and align on the product direction.',
          'LM',
          TaskPriority.low,
          -2,
          ['Team'],
        ),
      ],
    ),
  ];

  static KanbanTask _task(
    String id,
    String title,
    String description,
    String assignee,
    TaskPriority priority,
    int dueOffset,
    List<String> labels,
  ) {
    return KanbanTask(
      id: id,
      title: title,
      description: description,
      assignee: assignee,
      priority: priority,
      dueDate: DateTime(_today.year, _today.month, _today.day + dueOffset),
      labels: labels,
    );
  }

  @override
  Future<void> connect(
    String endpoint,
    void Function(Map<String, dynamic>) onMessage,
  ) => _remote.connect(endpoint, onMessage);

  @override
  Future<void> moveTask({
    required String taskId,
    required String operationId,
    required String sourceColumnId,
    required String targetColumnId,
    required int targetIndex,
  }) async {
    _remote.send({
      'type': 'task.move',
      'operation_id': operationId,
      'task_id': taskId,
      'source_column_id': sourceColumnId,
      'target_column_id': targetColumnId,
      'target_index': targetIndex,
    });
  }

  @override
  Future<void> createTask(
    BoardColumn column,
    Map<String, String> task, {
    required String operationId,
  }) async {
    _remote.send({
      'type': 'task.create',
      'operation_id': operationId,
      'column_id': column.id,
      ...task,
    });
  }

  @override
  Future<void> disconnect() => _remote.disconnect();
}
