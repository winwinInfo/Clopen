
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';
import '../models/opinion.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<loginProvider.AuthProvider>(context);
    final user = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          '의견 남기기',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 피드백 목록
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('feedback')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('의견을 불러오는데 실패했습니다');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final feedbacks = snapshot.data!.docs.map((doc) => 
                    Comment.fromMap(doc.data() as Map<String, dynamic>, doc.id)
                  ).toList();
                  
                  if (feedbacks.isEmpty) {
                    return const Center(
                      child: Text('첫 의견을 남겨보세요!'),
                    );
                  }

                  return ListView.builder(
                    itemCount: feedbacks.length,
                    itemBuilder: (context, index) {
                      final feedback = feedbacks[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: feedback.userPhotoUrl != null
                                ? NetworkImage(feedback.userPhotoUrl!)
                                : null,
                            child: feedback.userPhotoUrl == null
                                ? Text(feedback.userName[0].toUpperCase())
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                feedback.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(feedback.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(feedback.content),
                          trailing: user?['id'] == feedback.userId
                              ? IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteFeedback(feedback.id),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 피드백 입력 섹션
            if (user != null) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _feedbackController,
                        decoration: const InputDecoration(
                          hintText: '의견을 입력하세요...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _submitFeedback(user),
                      color: Colors.brown,
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: const Text(
                    '로그인하고 의견 남기기',
                    style: TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback(Map<String, dynamic> user) async {
    if (_feedbackController.text.trim().isEmpty) return;

    try {
      final feedback = Comment(
        id: '',
        userId: user['id'],
        userEmail: user['email'] ?? '',
        userName: user['name'] ?? '익명',
        content: _feedbackController.text.trim(),
        createdAt: DateTime.now(),
        userPhotoUrl: user['photoUrl'],
      );

      await _firestore.collection('feedback').add(feedback.toMap());

      _feedbackController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('의견 작성에 실패했습니다')),
      );
    }
  }


  Future<void> _deleteFeedback(String feedbackId) async {
    try {
      await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('의견 삭제에 실패했습니다')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}