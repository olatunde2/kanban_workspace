import 'package:get_it/get_it.dart';

import 'features/board/data/datasources/board_remote_data_source.dart';
import 'features/board/data/repositories/board_repository_impl.dart';
import 'features/board/domain/repositories/board_repository.dart';
import 'features/board/presentation/bloc/board_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt
    ..registerLazySingleton<BoardRemoteDataSource>(BoardRemoteDataSource.new)
    ..registerLazySingleton<BoardRepository>(
      () => BoardRepositoryImpl(getIt<BoardRemoteDataSource>()),
    )
    ..registerFactory(() => BoardBloc(getIt<BoardRepository>()));
}
