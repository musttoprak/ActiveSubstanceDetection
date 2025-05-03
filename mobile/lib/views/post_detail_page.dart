// post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/bloc/forum_detail_cubit.dart';
import 'package:mobile/models/request_models/forum_post_model.dart';
import 'package:mobile/models/request_models/forum_request_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailPage extends StatefulWidget {
  final ForumPost post;

  const PostDetailPage({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Gönderi detayını Cubit üzerinden yükle
    BlocProvider.of<ForumDetailCubit>(context).getPostDetail(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('id');

      final success = await BlocProvider.of<ForumDetailCubit>(context).addComment(
        widget.post.id,
        AddCommentRequest(userId: id.toString(),content: _commentController.text),
      );

      if (success) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum eklenirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum eklenirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gönderi Detayı'),
        backgroundColor: Colors.purple,
      ),
      body: BlocConsumer<ForumDetailCubit, ForumDetailState>(
        listener: (context, state) {
          if (state is ForumDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ForumDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is ForumDetailLoaded) {
            final post = state.post;
            return _buildContent(context, post, state.isPostLiked());
          } else {
            return const Center(
              child: Text('Gönderi yüklenirken bir hata oluştu'),
            );
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ForumPost post, bool isPostLiked) {
    final detailCubit = BlocProvider.of<ForumDetailCubit>(context);

    return Column(
      children: [
        // Gönderi İçeriği
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gönderi Başlığı
                Text(
                  post.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),

                // Gönderi Bilgileri
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getCategoryColor(post.category),
                      radius: 18,
                      child: Text(
                        post.author.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${post.author.role} • ${DateFormat('dd MMM yyyy, HH:mm').format(post.createdAt)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(post.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getCategoryColor(post.category).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        post.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getCategoryColor(post.category),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Gönderi sahibiyse veya yetkiliyse işlem menüsü
                    if (post.author.id == "1") // Örnek: Kullanıcı ID'si kontrolü
                      IconButton(
                        icon: Icon(Icons.more_vert),
                        onPressed: () {
                          _showPostOptionsBottomSheet(context, post);
                        },
                      ),
                  ],
                ),

                // Çözüldü İşareti
                if (post.isResolved)
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Bu konu çözüldü',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // İçerik
                Container(
                  margin: EdgeInsets.symmetric(vertical: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),

                // Etkileşim Butonları
                Row(
                  children: [
                    InkWell(
                      onTap: () => detailCubit.likePost(post.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPostLiked ? Colors.blue.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPostLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                              size: 16,
                              color: isPostLiked ? Colors.blue : Colors.grey.shade800,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${post.likes}',
                              style: TextStyle(
                                color: isPostLiked ? Colors.blue : Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 16,
                            color: Colors.grey.shade800,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${post.comments.length}',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),

                    // Çözüldü/Çözülmedi olarak işaretleme (sadece gönderi sahibi)
                    if (post.author.id == "1") // Örnek: Kullanıcı ID'si kontrolü
                      TextButton.icon(
                        icon: Icon(
                          post.isResolved
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          size: 16,
                        ),
                        label: Text(
                          post.isResolved
                              ? 'Çözülmedi'
                              : 'Çözüldü',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: post.isResolved ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          detailCubit.toggleResolved(post.id, !post.isResolved);
                        },
                      ),

                    // Paylaşım ve Kaydetme butonları
                    IconButton(
                      icon: Icon(Icons.share_outlined),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Paylaşım özelliği yapım aşamasında')),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.bookmark_border),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Kaydetme özelliği yapım aşamasında')),
                        );
                      },
                    ),
                  ],
                ),

                Divider(height: 32),

                // Yorumlar Başlığı
                Text(
                  'Yorumlar (${post.comments.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Yorumlar Listesi
                if (post.comments.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Henüz yorum yok',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'İlk yorumu sen yap!',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = post.comments[index];
                      // Cubuit durumundan yorum beğenilmiş mi kontrol et
                      final bool isCommentLiked =
                      BlocProvider.of<ForumDetailCubit>(context).state is ForumDetailLoaded
                          ? (BlocProvider.of<ForumDetailCubit>(context).state as ForumDetailLoaded).isCommentLiked(comment.id)
                          : false;

                      return _buildCommentCard(context, comment, post, isCommentLiked);
                    },
                  ),
              ],
            ),
          ),
        ),

        // Yorum Ekleme
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Yorum ekle...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  maxLines: null,
                ),
              ),
              SizedBox(width: 8),
              InkWell(
                onTap: _isSubmitting ? null : _submitComment,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(BuildContext context, ForumComment comment, ForumPost post, bool isCommentLiked) {
    final bool isAccepted = comment.isAccepted;
    final detailCubit = BlocProvider.of<ForumDetailCubit>(context);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAccepted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple.shade200,
                radius: 16,
                child: Text(
                  comment.author.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAccepted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Kabul Edildi',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () => detailCubit.likeComment(comment.id),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCommentLiked ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCommentLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                        size: 14,
                        color: isCommentLiked ? Colors.blue : Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${comment.likes}',
                        style: TextStyle(
                          color: isCommentLiked ? Colors.blue : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              if (post.author.id == "1" && !comment.isAccepted) // Sadece gönderi sahibi için
                TextButton.icon(
                  icon: Icon(
                    Icons.check_circle_outline,
                    size: 14,
                  ),
                  label: Text(
                    'Çözüm Olarak İşaretle',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size(0, 30),
                  ),
                  onPressed: () => detailCubit.acceptComment(comment.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostOptionsBottomSheet(BuildContext context, ForumPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                post.isResolved ? Icons.check_circle : Icons.check_circle_outline,
                color: post.isResolved ? Colors.green : Colors.grey,
              ),
              title: Text(
                post.isResolved ? 'Çözülmedi Olarak İşaretle' : 'Çözüldü Olarak İşaretle',
              ),
              onTap: () {
                Navigator.pop(context);
                BlocProvider.of<ForumDetailCubit>(context)
                    .toggleResolved(post.id, !post.isResolved);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Düzenle'),
              onTap: () {
                Navigator.pop(context);
                // Düzenleme sayfasına yönlendirme
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context, post.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.close),
              title: Text('İptal'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int postId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Gönderi Silme'),
          content: Text('Bu gönderiyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Post silme işlemi
                final success = await BlocProvider.of<ForumDetailCubit>(context).deletePost(postId);
                if (success) {
                  Navigator.pop(context, true); // Ana listeye geri dön
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'İlaç Etkileşimleri':
        return Colors.blue;
      case 'Etken Madde Soruları':
        return Colors.green;
      case 'Reçete Paylaşımı':
        return Colors.orange;
      case 'Profesyonel Gelişim':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}