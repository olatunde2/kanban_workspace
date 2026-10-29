# Northstar Kanban

A standalone Flutter client for a collaborative Kanban board. It uses BLoC for presentation state, GetIt for dependency injection, and a WebSocket data source behind a domain repository. The board includes sample data so it can be explored without a server.

## Run

```powershell
flutter pub get
flutter run
```

Use the settings icon in the top bar to connect to a `ws://` or `wss://` endpoint. The sample board works locally when the endpoint is left empty. Use `wss://` for production; an actual server is not included in this client project.

## WebSocket message contract

The client sends JSON messages over the open WebSocket:

```json
{
  "type": "task.move",
  "operation_id": "unique-operation-id",
  "task_id": "BD-101",
  "source_column_id": "progress",
  "target_column_id": "review",
  "target_index": 0
}
```

Task creation uses `type: "task.create"` with `operation_id`, `column_id`, and task fields (`task_id`, `title`, `description`, `assignee`, `priority`, `due_date`, `labels`).

For a move or task creation, the server should reply with either:

```json
{"type":"operation.accepted","operation_id":"unique-operation-id"}
```

or:

```json
{"type":"operation.rejected","operation_id":"unique-operation-id","reason":"Task is locked"}
```

The client applies moves optimistically. A rejection restores the board state from before the move or removes the task created optimistically. To broadcast another user's move, send:

```json
{
  "type": "task.move",
  "operation_id": "server-or-client-operation-id",
  "task_id": "BD-101",
  "source_column_id": "progress",
  "target_column_id": "review",
  "target_index": 0
}
```

The client applies remote `task.move` messages received from the server. Server-side authorization, validation, durable storage, conflict resolution, reconnection/backoff, and authentication are intentionally not implemented in this UI demo. Local demo changes are held in memory and reset when the app restarts. A failed/unavailable socket connection is reported in the UI; no server-side guarantee is implied.

## Architecture

- `features/board/domain`: board entities and repository contract
- `features/board/data`: WebSocket source and repository implementation
- `features/board/presentation`: BLoC and Flutter board UI
- `injection_container.dart`: GetIt registrations

## Validate

```powershell
dart format lib test
flutter analyze
flutter test
```
