import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/forum_post_cubit.dart';
import 'package:mobile/models/request_models/forum_post_model.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

class CommunityForumPage extends StatefulWidget {
  const CommunityForumPage({Key? key}) : super(key: key);

  @override
  _CommunityForumPageState createState() => _CommunityForumPageState();
}

class _CommunityForumPageState extends State<CommunityForumPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<String> _categories = [
    'Tümü',
    'İlaç Etkileşimleri',
    'Etken Madde Soruları',
    'Reçete Paylaşımı',
    'Profesyonel Gelişim'
  ];
  String _selectedCategory = 'Tümü';
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    // Cubit üzerinden post yükleme
    BlocProvider.of<ForumPostCubit>(context).getPosts(
        category: _selectedCategory == 'Tümü' ? null : _selectedCategory,
        query: _isSearching ? _searchController.text : null);
  }

  void _filterPostsBySearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: !_isSearching
            ? Text('Topluluk Forumu',
                style: TextStyle(fontWeight: FontWeight.bold))
            : TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Gönderi ara...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: _filterPostsBySearch,
                autofocus: true,
              ),
        backgroundColor: Colors.purple,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: TextStyle(
              color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          dividerHeight: 0,
          indicatorWeight: 3,
          onTap: (index) {
            // Sekme değiştiğinde yeniden yükle
            _loadPosts();
          },
          tabs: [
            Tab(text: 'Tüm Gönderiler'),
            Tab(text: 'En Çok Etkileşim'),
            Tab(text: 'Cevaplananlar'),
          ],
        ),
        actions: [
          _isSearching
              ? IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                    _loadPosts();
                  },
                )
              : IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showCategoryFilterDialog,
          ),
        ],
      ),
      // Cubit kullanarak gönderileri yükleme ve durum yönetimi
      body: BlocConsumer<ForumPostCubit, ForumPostState>(
        listener: (context, state) {
          if (state is ForumPostError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ForumPostLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.purple,
              ),
            );
          } else if (state is ForumPostLoaded) {
            return RefreshIndicator(
              onRefresh: _loadPosts,
              color: Colors.purple,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tüm gönderiler
                  _buildPostsList(
                    state.posts,
                    emptyMessage: 'Henüz gönderi yok',
                  ),

                  // En çok etkileşim alan gönderiler - Cubit'ten gelen verileri sırala
                  _buildPostsList(
                    List<ForumPost>.from(state.posts)
                      ..sort((a, b) => (b.likes + b.commentsCount)
                          .compareTo(a.likes + a.commentsCount)),
                    emptyMessage: 'Etkileşimli gönderi yok',
                  ),

                  // Cevaplanmış gönderiler
                  _buildPostsList(
                    state.posts.where((post) => post.isResolved).toList(),
                    emptyMessage: 'Cevaplanmış gönderi yok',
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Bir şeyler yanlış gitti. Lütfen tekrar deneyin.'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPosts,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostPage()),
          );

          if (result == true) {
            _loadPosts();
          }
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.add),
        tooltip: 'Yeni Gönderi Oluştur',
      ),
    );
  }

  Widget _buildPostsList(List<ForumPost> posts,
      {required String emptyMessage}) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'İlk gönderinizi oluşturmak için + butonuna tıklayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];

        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(ForumPost post) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailPage(post: post),
            ),
          );

          _loadPosts();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm')
                              .format(post.createdAt),
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
                        color:
                            _getCategoryColor(post.category).withOpacity(0.3),
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
                ],
              ),
              SizedBox(height: 12),
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${post.likes}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Spacer(),
                  if (post.isResolved)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Çözüldü',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kategori Seçin'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];

                return ListTile(
                  title: Text(category),
                  leading: Radio<String>(
                    value: category,
                    groupValue: _selectedCategory,
                    onChanged: (value) {
                      Navigator.pop(context);
                      setState(() {
                        _selectedCategory = value!;
                      });
                      _loadPosts();
                    },
                    activeColor: _getCategoryColor(category),
                  ),
                  trailing: category != 'Tümü'
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Kapat'),
            ),
          ],
        );
      },
    );
  }
}
