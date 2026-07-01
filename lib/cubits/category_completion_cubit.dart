import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/category_service.dart';

class CategoryCompletionCubit extends Cubit<Map<String, Map<String, int>>> {
  final CategoryService _service;

  CategoryCompletionCubit(this._service) : super({});

  Future<void> load() async {
    try {
      final data = await _service.getCompletionStatus();
      emit(data);
    } catch (_) {}
  }
}
