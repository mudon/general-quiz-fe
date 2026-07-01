import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoriesState {
  final List<Category>? categories;
  final bool loading;
  final String? error;

  const CategoriesState({this.categories, this.loading = true, this.error});

  CategoriesState copyWith({List<Category>? categories, bool? loading, String? error}) {
    return CategoriesState(
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoryService _service;

  CategoriesCubit(this._service) : super(const CategoriesState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final cats = await _service.getCategories();
      emit(state.copyWith(categories: cats, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
