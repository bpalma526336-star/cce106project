import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_quiz/model/category.dart';
import 'package:smart_quiz/model/question.dart';
import 'package:smart_quiz/model/quiz.dart';
import 'package:smart_quiz/theme/theme.dart';

class AddQuizScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  const AddQuizScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

class QuestionFromItem {
  final TextEditingController questionController;
  final List<TextEditingController> optionsControllers;
  int correctOptionIndex;

  QuestionFromItem({
    required this.questionController,
    required this.optionsControllers,
    required this.correctOptionIndex,
  });

  void dispose() {
    questionController.dispose();
    optionsControllers.forEach((element) {
      element.dispose();
    });
  }
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _selectedCategoryId;
  List<QuestionFromItem> _questionsItems = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _addQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();
    for (var item in _questionsItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionsItems.add(
        QuestionFromItem(
          questionController: TextEditingController(),
          optionsControllers: List.generate(4, (_) => TextEditingController()),
          correctOptionIndex: 0,
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questionsItems[index].dispose();
      _questionsItems.removeAt(index);
    });
  }

  Future<void> _SaveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select a category")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final questions = _questionsItems
          .map(
            (item) => Question(
              text: item.questionController.text.trim(),
              options: item.optionsControllers
                  .map((e) => e.text.trim())
                  .toList(),
              correctOptionIndex: item.correctOptionIndex,
            ),
          )
          .toList();

      await _firestore
          .collection("quizzes")
          .doc()
          .set(
            Quiz(
              id: _firestore.collection("quizzes").doc().id,
              title: _titleController.text.trim(),
              categoryId: _selectedCategoryId!,
              timeLimit: int.parse(_timeLimitController.text.trim()),
              questions: questions,
              createdAt: DateTime.now(),
              updatedAt: null,
            ).toMap(),
          );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Quiz added Successfully")));
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Quiz added successfully",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to add quiz",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: Text(
          widget.categoryName != null
              ? "Add ${widget.categoryName} Quiz"
              : "Add Quiz Question",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _SaveQuiz,
            icon: Icon(Icons.save, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Quiz Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    labelText: "Title",
                    hintText: "Enter quiz title",
                    prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter quiz title";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                if (widget.categoryId == null)
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('categories')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text("Error");
                      }
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }

                      final categories = snapshot.data!.docs
                          .map(
                            (doc) => Category.fromMap(
                              doc.id,
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                      return DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: "Category",
                          hintText: "Select Category",
                          prefixIcon: Icon(
                            Icons.category,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),

                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          value == null ? "Please select a category" : null;
                        },
                      );
                    },
                  ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _timeLimitController,
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 20),
                    labelText: "Time Limit (in minutes)",
                    hintText: "Enter Time Limit",
                    prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter time limit";
                    }
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) {
                      return "Please enter a valid time limit";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuestion,
                          label: Text("Add Question"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ..._questionsItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final QuestionFromItem question = entry.value;

                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Question ${index + 1}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  if (_questionsItems.length > 1)
                                    IconButton(
                                      onPressed: () {
                                        _removeQuestion(index);
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: question.questionController,
                                decoration: InputDecoration(
                                  labelText: "Question",
                                  hintText: "Enter question",
                                  prefixIcon: Icon(
                                    Icons.question_mark,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter question";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              ...question.optionsControllers.asMap().entries.map(
                                (entry) {
                                  final optionIndex = entry.key;
                                  final controller = entry.value;

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Radio<int>(
                                          activeColor: AppTheme.primaryColor,
                                          value: optionIndex,
                                          groupValue:
                                              question.correctOptionIndex,
                                          onChanged: (value) {
                                            setState(() {
                                              question.correctOptionIndex =
                                                  value!;
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            controller: controller,
                                            decoration: InputDecoration(
                                              labelText:
                                                  "Option ${optionIndex + 1} ",
                                              hintText: "Enter Option",
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return "Please enter option";
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _SaveQuiz,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Save Quiz",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
