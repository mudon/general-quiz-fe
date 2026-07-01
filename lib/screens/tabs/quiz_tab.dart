import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_bubble.dart';
import '../quiz/question_screen.dart';

class QuizTab extends StatefulWidget {
  final CategoryService categoryService;
  final QuizService quizService;

  const QuizTab({
    super.key,
    required this.categoryService,
    required this.quizService,
  });

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  List<Category>? _categories;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await widget.categoryService.getCategories();
      if (mounted) {
        setState(() { _categories = cats; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  void _onCategoryTap(Category cat) {
    if (cat.children.isNotEmpty) {
      _showSubcategories(cat);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionScreen(
            quizService: widget.quizService,
            categoryId: cat.id,
            categoryName: cat.name,
          ),
        ),
      );
    }
  }

  void _showSubcategories(Category parent) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(parent.name,
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < parent.children.length; i++)
                    CategoryBubble(
                      category: parent.children[i],
                      colorIndex: parent.depth + i + 1,
                      onTap: () => _onCategoryTap(parent.children[i]),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧠',
                style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('QUIZZTOPIA',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Loading topics...',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😵', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() { _loading = true; _error = null; });
                  _loadCategories();
                },
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories == null || _categories!.isEmpty) {
      return const Center(
        child: Text('😴 No topics yet!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outline, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 0,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('👇', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text(
                    'PICK A TOPIC TO START!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('👇', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int i = 0; i < _categories!.length; i++)
                  CategoryBubble(
                    category: _categories![i],
                    colorIndex: i,
                    onTap: () => _onCategoryTap(_categories![i]),
                  ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
