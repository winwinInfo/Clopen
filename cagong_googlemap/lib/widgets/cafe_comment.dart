// widgets/comments_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // User 타입을 위해 필요
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';  // LoginPage import
import '../models/opinion.dart';

class CommentsSection extends StatefulWidget {
 final double cafeId;

 const CommentsSection({super.key, required this.cafeId});

 @override
 _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
 final TextEditingController _commentController = TextEditingController();
 final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 String get _cafeIdString => widget.cafeId.toString();

 @override
 Widget build(BuildContext context) {
   final authProvider = Provider.of<loginProvider.AuthProvider>(context);
   final user = authProvider.user;

   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       // 댓글 목록
       StreamBuilder<QuerySnapshot>(
         stream: _firestore
             .collection('cafes')
             .doc(_cafeIdString)
             .collection('comments')
             .orderBy('createdAt', descending: true)
             .snapshots(),
         builder: (context, snapshot) {
           if (snapshot.hasError) {
             return const Text('댓글을 불러오는데 실패했습니다');
           }

           if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
           }

           final comments = snapshot.data!.docs.map((doc) => 
             Comment.fromMap(doc.data() as Map<String, dynamic>, doc.id)
           ).toList();
           
           if (comments.isEmpty) {
             return const Center(
               child: Padding(
                 padding: EdgeInsets.all(16.0),
                 child: Text('첫 댓글을 남겨보세요!'),
               ),
             );
           }

           return ListView.builder(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             itemCount: comments.length,
             itemBuilder: (context, index) {
               final comment = comments[index];
               return Card(
                color: Colors.white,
                 child: ListTile(
                   leading: CircleAvatar(
                     backgroundImage: comment.userPhotoUrl != null
                         ? NetworkImage(comment.userPhotoUrl!)
                         : null,
                     child: comment.userPhotoUrl == null
                         ? Text(comment.userName[0].toUpperCase())
                         : null,
                   ),
                   title: Row(
                     children: [
                       Text(
                         comment.userName,
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(width: 8),
                       Text(
                         _formatDate(comment.createdAt),
                         style: const TextStyle(
                           fontSize: 12,
                           color: Colors.grey,
                         ),
                       ),
                     ],
                   ),
                   subtitle: Text(comment.content),
                   trailing: user?.uid == comment.userId
                       ? IconButton(
                           icon: const Icon(Icons.delete),
                           onPressed: () => _deleteComment(comment.id),
                         )
                       : null,
                 ),
               );
             },
           );
         },
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
               onPressed: () => _submitComment(user),
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

 Future<void> _submitComment(User user) async {
   if (_commentController.text.trim().isEmpty) return;

   try {
     final comment = Comment(
       id: '', // Firestore가 생성
       userId: user.uid,
       userEmail: user.email!,
       userName: user.displayName ?? '익명',
       content: _commentController.text.trim(),
       createdAt: DateTime.now(),
       userPhotoUrl: user.photoURL,
     );

     await _firestore
         .collection('cafes')
         .doc(_cafeIdString)
         .collection('comments')
         .add(comment.toMap());

     _commentController.clear();
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('댓글 작성에 실패했습니다')),
     );
   }
 }

 Future<void> _deleteComment(String commentId) async {
   try {
     await _firestore
         .collection('cafes')
         .doc(_cafeIdString)
         .collection('comments')
         .doc(commentId)
         .delete();
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('댓글 삭제에 실패했습니다')),
     );
   }
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