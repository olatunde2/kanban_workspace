import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/board_column.dart';
import '../../domain/entities/kanban_task.dart';
import '../bloc/board_bloc.dart';

const _uuid = Uuid();
const _ink = Color(0xFF22223A);
const _muted = Color(0xFF85859A);

class BoardPage extends StatelessWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoardBloc, BoardState>(
      listenWhen: (previous, current) => previous.error != current.error,
      listener: (context, state) {
        if (state.error case final error?) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(error)));
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const _TopBar(),
              const _BoardSummary(),
              Expanded(
                child: BlocBuilder<BoardBloc, BoardState>(
                  builder: (context, state) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 700;
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.fromLTRB(
                            compact ? 18 : 32,
                            12,
                            compact ? 18 : 32,
                            28,
                          ),
                          itemCount: state.columns.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder: (context, index) => _BoardLane(
                            column: state.columns[index],
                            compact: compact,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateTask(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New task'),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF5B5BD6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.grid_view_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'northstar',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              Text(
                'PRODUCT STUDIO',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          _ConnectionBadge(),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'WebSocket settings',
            onPressed: () => _showConnectionSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFFFE3D4),
            child: Text(
              'AK',
              style: TextStyle(
                color: Color(0xFF9B563C),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      buildWhen: (a, b) => a.connection != b.connection,
      builder: (context, state) {
        final (label, color, icon) = switch (state.connection) {
          BoardConnection.local => (
            'Local demo',
            const Color(0xFF85859A),
            Icons.cloud_off_rounded,
          ),
          BoardConnection.connecting => (
            'Connecting',
            const Color(0xFFE3A63F),
            Icons.sync_rounded,
          ),
          BoardConnection.connected => (
            'Live',
            const Color(0xFF42A88A),
            Icons.wifi_rounded,
          ),
          BoardConnection.disconnected => (
            'Offline',
            const Color(0xFFE07878),
            Icons.wifi_off_rounded,
          ),
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoardSummary extends StatelessWidget {
  const _BoardSummary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      buildWhen: (a, b) => a.taskCount != b.taskCount,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 8),
          child: Row(
            children: [
              const Text(
                'Product roadmap',
                style: TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(width: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8F8),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${state.taskCount} tasks',
                  style: const TextStyle(
                    color: Color(0xFF5B5BD6),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Filter tasks',
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, color: _muted),
              ),
              IconButton(
                tooltip: 'More board options',
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded, color: _muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoardLane extends StatelessWidget {
  const _BoardLane({required this.column, required this.compact});

  final BoardColumn column;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Color(column.color);
    return DragTarget<KanbanTask>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final source = context.read<BoardBloc>().state.columns.firstWhere(
          (lane) => lane.tasks.any((task) => task.id == details.data.id),
        );
        context.read<BoardBloc>().add(
          TaskMoved(
            taskId: details.data.id,
            sourceColumnId: source.id,
            targetColumnId: column.id,
            targetIndex: column.tasks.length,
            operationId: _uuid.v4(),
          ),
        );
      },
      builder: (context, candidates, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: compact ? 300 : 312,
          decoration: BoxDecoration(
            color: candidates.isNotEmpty
                ? color.withValues(alpha: 0.08)
                : const Color(0xFFEDEDF3),
            borderRadius: BorderRadius.circular(18),
            border: candidates.isNotEmpty
                ? Border.all(color: color.withValues(alpha: 0.55), width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 12, 13),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      column.title,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CountPill(count: column.tasks.length, color: color),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Add task to ${column.title}',
                      onPressed: () =>
                          _showCreateTask(context, columnId: column.id),
                      icon: const Icon(Icons.add_rounded, size: 19),
                    ),
                    const Icon(Icons.more_horiz_rounded, color: _muted),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  children: [
                    for (final task in column.tasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TaskDragCard(task: task, column: column),
                      ),
                    if (column.tasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 25),
                        child: Center(
                          child: Text(
                            'Drop a task here',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$count',
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10),
    ),
  );
}

class _TaskDragCard extends StatelessWidget {
  const _TaskDragCard({required this.task, required this.column});

  final KanbanTask task;
  final BoardColumn column;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<KanbanTask>(
      data: task,
      feedback: SizedBox(
        width: 285,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(15),
          child: _TaskCard(task: task),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _TaskCard(task: task)),
      child: DragTarget<KanbanTask>(
        onWillAcceptWithDetails: (details) => details.data.id != task.id,
        onAcceptWithDetails: (details) {
          context.read<BoardBloc>().add(
            TaskMoved(
              taskId: details.data.id,
              sourceColumnId: context
                  .read<BoardBloc>()
                  .state
                  .columns
                  .firstWhere(
                    (lane) =>
                        lane.tasks.any((item) => item.id == details.data.id),
                  )
                  .id,
              targetColumnId: column.id,
              targetIndex: column.tasks.indexWhere(
                (item) => item.id == task.id,
              ),
              operationId: _uuid.v4(),
            ),
          );
        },
        builder: (context, candidates, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: candidates.isEmpty
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF5B5BD6).withValues(alpha: 0.15),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: _TaskCard(task: task),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final KanbanTask task;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      TaskPriority.low => const Color(0xFF42A88A),
      TaskPriority.medium => const Color(0xFFE3A63F),
      TaskPriority.high => const Color(0xFFE07878),
    };
    final due = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    final today = DateTime.now();
    final isOverdue = due.isBefore(
      DateTime(today.year, today.month, today.day),
    );
    final dueLabel = isOverdue
        ? 'Overdue'
        : due == DateTime(today.year, today.month, today.day)
        ? 'Today'
        : '${_month(due.month)} ${due.day}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE7E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                task.id.length > 7 ? 'NEW TASK' : task.id,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (task.pending)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else
                const Icon(Icons.more_horiz_rounded, color: _muted, size: 19),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final label in task.labels) _LabelPill(label: label),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(Icons.flag_rounded, color: priorityColor, size: 14),
              const SizedBox(width: 4),
              Text(
                task.priority.name[0].toUpperCase() +
                    task.priority.name.substring(1),
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.calendar_today_rounded,
                color: isOverdue ? const Color(0xFFE07878) : _muted,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                dueLabel,
                style: TextStyle(
                  color: isOverdue ? const Color(0xFFE07878) : _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 12,
                backgroundColor: _avatarColor(task.assignee),
                child: Text(
                  task.assignee,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelPill extends StatelessWidget {
  const _LabelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label.toLowerCase()) {
      'design' => const Color(0xFF6F65C8),
      'engineering' || 'mobile' => const Color(0xFF4386B6),
      'research' || 'product' => const Color(0xFFD17A42),
      'q3' => const Color(0xFFBC5C83),
      _ => const Color(0xFF6E8D77),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<void> _showCreateTask(BuildContext context, {String? columnId}) async {
  final bloc = context.read<BoardBloc>();
  final columns = bloc.state.columns;
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final assignee = TextEditingController(text: 'AK');
  var selectedColumn = columnId ?? columns.first.id;
  var priority = TaskPriority.medium;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Create a task'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Task name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Add a task name'
                      : null,
                ),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 1,
                  maxLines: 3,
                ),
                TextField(
                  controller: assignee,
                  decoration: const InputDecoration(
                    labelText: 'Assignee initials',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedColumn,
                  decoration: const InputDecoration(labelText: 'Column'),
                  items: [
                    for (final column in columns)
                      DropdownMenuItem(
                        value: column.id,
                        child: Text(column.title),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedColumn = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: [
                    for (final item in TaskPriority.values)
                      DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.name[0].toUpperCase() + item.name.substring(1),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => priority = value);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              bloc.add(
                TaskCreated(
                  columnId: selectedColumn,
                  title: title.text.trim(),
                  description: description.text.trim(),
                  assignee: assignee.text.trim().isEmpty
                      ? 'AK'
                      : assignee.text.trim().toUpperCase(),
                  priority: priority,
                  dueDate: DateTime.now().add(const Duration(days: 3)),
                  labels: const ['New'],
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Create task'),
          ),
        ],
      ),
    ),
  );
  title.dispose();
  description.dispose();
  assignee.dispose();
}

Future<void> _showConnectionSettings(BuildContext context) async {
  final bloc = context.read<BoardBloc>();
  final controller = TextEditingController(text: bloc.state.endpoint);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Live collaboration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect a WebSocket server to share board activity with your team.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'WebSocket endpoint',
              hintText: 'wss://example.com/board',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Leave empty to use the local demo board.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            bloc.add(const BoardEndpointChanged(''));
            Navigator.pop(dialogContext);
          },
          child: const Text('Use local'),
        ),
        FilledButton(
          onPressed: () {
            bloc.add(BoardEndpointChanged(controller.text));
            Navigator.pop(dialogContext);
          },
          child: const Text('Connect'),
        ),
      ],
    ),
  );
  controller.dispose();
}

Color _avatarColor(String initials) {
  const colors = [
    Color(0xFFFFE3D4),
    Color(0xFFDCE9FF),
    Color(0xFFE6DDF7),
    Color(0xFFD8F0E7),
  ];
  return colors[initials.codeUnits.fold<int>(0, (sum, char) => sum + char) %
      colors.length];
}

String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
