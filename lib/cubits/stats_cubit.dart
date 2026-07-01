import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/stats.dart';
import '../services/stats_service.dart';

class StatsState {
  final UserStats? stats;
  final List<CategoryStat>? categoryStats;
  final bool loading;
  final String? error;

  const StatsState({this.stats, this.categoryStats, this.loading = true, this.error});

  StatsState copyWith({
    UserStats? stats,
    List<CategoryStat>? categoryStats,
    bool? loading,
    String? error,
  }) {
    return StatsState(
      stats: stats ?? this.stats,
      categoryStats: categoryStats ?? this.categoryStats,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class StatsCubit extends Cubit<StatsState> {
  final StatsService _service;

  StatsCubit(this._service) : super(const StatsState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final results = await Future.wait([
        _service.getStats(),
        _service.getCategoryStats(),
      ]);
      emit(state.copyWith(
        stats: results[0] as UserStats,
        categoryStats: results[1] as List<CategoryStat>,
        loading: false,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
