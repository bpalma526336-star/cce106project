import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_quiz/model/category.dart';
import 'package:smart_quiz/model/quiz.dart';
import 'package:smart_quiz/theme/theme.dart';
import 'package:smart_quiz/view/admin/add_quiz_screen.dart';
import 'package:smart_quiz/view/admin/edit_quiz_screen.dart';

class ManageQuizesScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  const ManageQuizesScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<ManageQuizesScreen> createState() => _ManageQuizesScreenState();
}

class _ManageQuizesScreenState extends State<ManageQuizesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  String? _selectedCategoryId;
  List<Category> _categories = [];
  Category? _initialCategory;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final querySnapshot = await _firestore.collection("categories").get();
      final categories = querySnapshot.docs
          .map(
            (doc) =>
                Category.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();

      setState(() {
        _categories = categories;
        if (widget.categoryId != null) {
          _initialCategory = categories.firstWhere(
            (category) => category.id == widget.categoryId,
            orElse: () => Category(
              id: widget.categoryId!,
              name: "Unknown",
              description: '',
            ),
          );
          _selectedCategoryId = _initialCategory?.id;
        }
      });
    } catch (e) {
      debugPrint("Error Fetching Categories: $e");
    }
  }

  Stream<QuerySnapshot> _getQuizStream() {
    Query query = _firestore.collection("quizzes");

    final filterCategoryId = _selectedCategoryId ?? widget.categoryId;
    if (filterCategoryId != null) {
      query = query.where("categoryId", isEqualTo: filterCategoryId);
    }

    if (_searchQuery.isNotEmpty) {
      query = query.where("name", isGreaterThanOrEqualTo: _searchQuery);
    }

    return query.snapshots();
  }

  Widget _buildTitle() {
    final categoryId = _selectedCategoryId ?? widget.categoryId;
    if (categoryId == null) {
      return const Text(
        "All Quizzes",
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('categories').doc(categoryId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text(
            "Loading...",
            style: TextStyle(fontWeight: FontWeight.bold),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final category = Category.fromMap(categoryId, data);
        return Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddQuizScreen(
                    categoryId: widget.categoryId,
                    categoryName: widget.categoryId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                fillColor: Colors.white,
                hintText: "Search Quizzes",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 18,
                ),
                border: const OutlineInputBorder(),
                hintText: "Category",
              ),
              value: _selectedCategoryId,
              items: [
                const DropdownMenuItem(
                  child: Text("All Categories"),
                  value: null,
                ),
                if (_initialCategory != null &&
                    _categories.every((c) => c.id != _initialCategory!.id))
                  DropdownMenuItem(
                    child: Text(_initialCategory!.name),
                    value: _initialCategory!.id,
                  ),
                ..._categories.map(
                  (category) => DropdownMenuItem(
                    child: Text(category.name),
                    value: category.id,
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getQuizStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error"));
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                final quizzes = snapshot.data!.docs
                    .map(
                      (doc) => Quiz.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .where(
                      (quiz) =>
                          _searchQuery.isEmpty ||
                          quiz.title.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

                if (quizzes.isEmpty) {
                  return Center(
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
                          "No quizzes yet",
                          style: TextStyle(
                            color: AppTheme.textSecondayColor,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              (context),
                              MaterialPageRoute(
                                builder: (context) => AddQuizScreen(
                                  categoryId: widget.categoryId,
                                  categoryName: widget.categoryId,
                                ),
                              ),
                            );
                          },
                          child: Text("Add Quiz"),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final Quiz quiz = quizzes[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.quiz_rounded,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          quiz.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.question_answer_outlined,
                                  size: 16,
                                  color: AppTheme.textSecondayColor,
                                ),
                                SizedBox(width: 4),
                                Text("${quiz.questions.length} Questions"),
                                SizedBox(width: 16),
                                Icon(Icons.timer_outlined, size: 16),
                                SizedBox(width: 4),
                                Text("${quiz.timeLimit} mins"),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "edit",
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.edit,
                                  color: AppTheme.primaryColor,
                                ),
                                title: Text("Edit"),
                              ),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                title: Text("Delete"),
                              ),
                            ),
                          ],
                          onSelected: (value) =>
                              _handleQuizAction(context, value, quiz),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuizAction(
    BuildContext context,
    String value,
    Quiz quiz,
  ) async {
    if (value == "edit") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditQuizScreen(quiz: quiz)),
      );
    } else if (value == "delete") {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Delete Quiz"),
          content: Text("Are you sure you want to delete this quiz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _firestore.collection("quizzes").doc(quiz.id).delete();
      }
    }
  }
}
