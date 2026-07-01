import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class ReviewState {
  final List<DueReviewItem>? items;
  final bool loading;
  final String? error;

  const ReviewState({this.items, this.loading = true, this.error});

  ReviewState copyWith({List<DueReviewItem>? items, bool? loading, String? error}) {
    return ReviewState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class ReviewCubit extends Cubit<ReviewState> {
  final ReviewService _service;

  ReviewCubit(this._service) : super(const ReviewState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final page = await _service.getDueForReview();
      emit(state.copyWith(items: page.items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
