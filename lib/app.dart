import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/board/presentation/bloc/board_bloc.dart';
import 'features/board/presentation/pages/board_page.dart';
import 'injection_container.dart';

class KanbanApp extends StatelessWidget {
  const KanbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Northstar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B5BD6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F6FA),
        fontFamily: 'Roboto',
      ),
      home: BlocProvider(
        create: (_) => getIt<BoardBloc>()..add(const BoardStarted()),
        child: const BoardPage(),
      ),
    );
  }
}
