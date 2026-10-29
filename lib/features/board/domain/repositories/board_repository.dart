import '../entities/board_column.dart';

abstract interface class BoardRepository {
  List<BoardColumn> get initialColumns;

  Future<void> connect(
    String endpoint,
    void Function(Map<String, dynamic>) onMessage,
  );

  Future<void> moveTask({
    required String taskId,
    required String operationId,
    required String sourceColumnId,
    required String targetColumnId,
    required int targetIndex,
  });

  Future<void> createTask(
    BoardColumn column,
    Map<String, String> task, {
    required String operationId,
  });

  Future<void> disconnect();
}
