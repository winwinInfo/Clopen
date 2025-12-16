import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

class CommentsSection extends StatefulWidget {
 final double cafeId;

 const CommentsSection({super.key, required this.cafeId});

 @override
 State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
 final TextEditingController _commentController = TextEditingController();
 List<Comment> _comments = [];
 bool _isLoading = true;

 int get _cafeIdInt => widget.cafeId.toInt();

 @override
 void initState() {
   super.initState();
   _loadComments();
 }

 Future<void> _loadComments() async {
   try {
     setState(() => _isLoading = true);
     final comments = await CommentService.getComments(_cafeIdInt);
     setState(() {
       _comments = comments;
       _isLoading = false;
     });
   } catch (e) {
     setState(() => _isLoading = false);
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('댓글을 불러오는데 실패했습니다: $e')),
       );
     }
   }
 }

 @override
 Widget build(BuildContext context) {
   final authProvider = Provider.of<loginProvider.AuthProvider>(context);
   final user = authProvider.userData;

   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('댓글 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),

       // 댓글 입력 섹션
       Padding(
         padding: const EdgeInsets.symmetric(horizontal: 16.0),
         child: user != null
           ? Row(
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
                   onPressed: _submitComment,
                   color: Colors.brown,
                 ),
               ],
             )
           : Center(
               child: TextButton(
                 onPressed: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (context) => LoginPage()),
                   );
                 },
                 child: const Text(
                   '로그인하고 댓글 남기기',
                   style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                 ),
               ),
             ),
       ),

       const SizedBox(height: 16),

       // 댓글 목록
       _isLoading
         ? const Center(child: CircularProgressIndicator())
         : _comments.isEmpty
           ? const Padding(
               padding: EdgeInsets.all(16.0),
               child: Center(child: Text('첫 댓글을 남겨보세요!')),
             )
           : ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: _comments.length,
               itemBuilder: (context, index) {
                 final comment = _comments[index];
                 return _buildCommentItem(comment, user);
               },
             ),
     ],
   );
 }

 Widget _buildCommentItem(Comment comment, Map<String, dynamic>? user) {
   final isMyComment = user != null && comment.userId == user['id'];

   return Container(
     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
     decoration: const BoxDecoration(
       border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
     ),
     child: Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         CircleAvatar(
           backgroundColor: Colors.grey[300],
           backgroundImage: comment.userPhoto != null && comment.userPhoto!.isNotEmpty
             ? NetworkImage(comment.userPhoto!)
             : null,
           child: comment.userPhoto == null || comment.userPhoto!.isEmpty
             ? const Icon(Icons.person, color: Colors.white)
             : null,
         ),
         const SizedBox(width: 12),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Text(
                     comment.userNickname,
                     style: const TextStyle(fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(width: 8),
                   Text(
                     _formatDate(comment.createdAt),
                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                   ),
                 ],
               ),
               const SizedBox(height: 4),
               Text(comment.content),
             ],
           ),
         ),
         if (isMyComment)
           IconButton(
             icon: const Icon(Icons.delete, size: 20),
             color: Colors.red,
             onPressed: () => _deleteComment(comment.id),
           ),
       ],
     ),
   );
 }

 Future<void> _submitComment() async {
   if (_commentController.text.trim().isEmpty) return;

   final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
   final jwtToken = authProvider.jwtToken;

   if (jwtToken == null) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('로그인이 필요합니다')),
     );
     return;
   }

   try {
     await CommentService.createComment(
       cafeId: _cafeIdInt,
       content: _commentController.text.trim(),
       jwtToken: jwtToken,
     );

     _commentController.clear();
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('댓글이 등록되었습니다')),
     );
     _loadComments();
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('댓글 작성 실패: $e')),
     );
   }
 }

 Future<void> _deleteComment(int commentId) async {
   final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
   final jwtToken = authProvider.jwtToken;

   if (jwtToken == null) return;

   try {
     await CommentService.deleteComment(
       commentId: commentId,
       jwtToken: jwtToken,
     );

     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('댓글이 삭제되었습니다')),
     );
     _loadComments();
   } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('댓글 삭제 실패: $e')),
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