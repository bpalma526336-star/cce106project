import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_quiz/model/category.dart';
import 'package:smart_quiz/model/quiz.dart';
import 'package:smart_quiz/theme/theme.dart';
import 'package:smart_quiz/view/user/quiz_play_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Quiz> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch_quizzes();
  }

  Future<void> _fetch_quizzes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('categoryId', isEqualTo: widget.category.id)
          .get();

      setState(() {
        _quizzes = snapshot.docs
            .map((doc) => Quiz.fromMap(doc.id, doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to Load quizzes")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _quizzes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: AppTheme.textSecondayColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No quizzes available in this category",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondayColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Go back"),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primaryColor,
                  expandedHeight: 230,
                  floating: false,
                  pinned: true,
                  leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.category.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    background: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            widget.category.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _quizzes[index];
                        return _buildQuizCard(quiz, index);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuizCard(Quiz quiz, int index) {
    return Card(
          margin: EdgeInsets.only(bottom: 10),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPlayScreen(quiz: quiz),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.quiz_rounded,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.question_answer_outlined, size: 16),
                                SizedBox(width: 4),
                                Text('${quiz.questions.length} Question'),
                                SizedBox(width: 16),
                                Icon(Icons.timer_outlined, size: 16),
                                SizedBox(width: 4),
                                Text('${quiz.timeLimit} mins'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_outlined,
                    size: 30,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .slideX(begin: 0.5, end: 0, duration: Duration(milliseconds: 300))
        .fadeIn();
  }
}
