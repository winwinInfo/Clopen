// widgets/comments_section.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';  // LoginPage import
import '../models/opinion.dart';

class CommentsSection extends StatefulWidget {
 final double cafeId;

 const CommentsSection({super.key, required this.cafeId});

 @override
 State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
 final TextEditingController _commentController = TextEditingController();

 String get _cafeIdString => widget.cafeId.toString();

 @override
 Widget build(BuildContext context) {
   final authProvider = Provider.of<loginProvider.AuthProvider>(context);
   final user = authProvider.userData;

   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       // 댓글 목록 (Firebase 기능 비활성화)
      const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('댓글 기능은 현재 비활성화되어 있습니다.\n(Flask 연결 후 다시 활성화됩니다)'),
        ),
      ),

       // 댓글 입력 섹션
       if (user != null) ...[
         const SizedBox(height: 16),
         Row(
           children: [
             Expanded(
               child: TextField(
                 controller: _commentController,
                 decoration: const InputDecoration(
                   hintText: '댓글을 입력하세요...',
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
               onPressed: user != null ? () => _submitComment(user) : null,
               color: Colors.brown,
             ),
           ],
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
               '로그인하고 댓글 남기기',
               style: TextStyle(
                 color: Colors.brown,
                 fontWeight: FontWeight.bold,
               ),
             ),
           ),
         ),
       ],
     ],
   );
 }

 Future<void> _submitComment(Map<String, dynamic> user) async {
   if (_commentController.text.trim().isEmpty) return;

   try {
     // Firebase 기능 비활성화 - 임시 처리
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('댓글 기능은 현재 비활성화되어 있습니다')),
     );
     _commentController.clear();
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('댓글 작성에 실패했습니다')),
     );
   }
 }

 Future<void> _deleteComment(String commentId) async {
   // Firebase 기능 비활성화
 }

 String _formatDate(DateTime date) {
   return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
 }

 @override
 void dispose() {
   _commentController.dispose();
   super.dispose();
 }
}