part of 'board_bloc.dart';

enum BoardConnection { local, connecting, connected, disconnected }

final class BoardState extends Equatable {
  const BoardState({
    required this.columns,
    this.endpoint = '',
    this.connection = BoardConnection.local,
    this.error,
  });

  final List<BoardColumn> columns;
  final String endpoint;
  final BoardConnection connection;
  final String? error;

  int get taskCount =>
      columns.fold(0, (sum, column) => sum + column.tasks.length);

  BoardState copyWith({
    List<BoardColumn>? columns,
    String? endpoint,
    BoardConnection? connection,
    String? error,
    bool clearError = false,
  }) {
    return BoardState(
      columns: columns ?? this.columns,
      endpoint: endpoint ?? this.endpoint,
      connection: connection ?? this.connection,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [columns, endpoint, connection, error];
}
