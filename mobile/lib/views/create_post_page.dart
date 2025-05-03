// create_post_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/forum_post_cubit.dart';
import 'package:mobile/models/request_models/forum_request_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = 'İlaç Etkileşimleri';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'İlaç Etkileşimleri',
    'Etken Madde Soruları',
    'Reçete Paylaşımı',
    'Profesyonel Gelişim'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('id');
      try {
        // Cubit üzerinden gönderi oluştur
        final request = CreatePostRequest(
          userId: id.toString(),
          title: _titleController.text,
          content: _contentController.text,
          category: _selectedCategory,
        );

        final success = await BlocProvider.of<ForumPostCubit>(context).createPost(request);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gönderi başarıyla oluşturuldu'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // true değeri formun gönderildiğini belirtir
        } else {
          // Hata durumu cubit listener'da ele alınacak
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gönderi oluşturulurken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Gönderi Oluştur'),
        backgroundColor: Colors.purple,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              'Paylaş',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<ForumPostCubit, ForumPostState>(
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori Seçimi
                Text(
                  'Kategori',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                _buildCategoryDropdown(),
                SizedBox(height: 16),

                // Başlık
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Gönderiniz için açıklayıcı bir başlık yazın',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir başlık girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // İçerik
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'İçerik',
                    hintText: 'Sorununuzu veya paylaşmak istediğiniz bilgiyi detaylı açıklayın',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen içerik girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // İpuçları
                _buildTipsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Kategori dropdown widget'ı
  Widget _buildCategoryDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 16,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
          items: _categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(value),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // İpuçları kısmı
  Widget _buildTipsSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İpuçları:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 8),
          _buildTip('Soru sorarken, ilgili meslektaşlarınıza gerekli tüm bilgileri sağlayın.'),
          _buildTip('Mahremiyete dikkat edin, hasta bilgilerini paylaşmayın.'),
          _buildTip('İlaç adlarını ve dozları açıkça belirtin.'),
          _buildTip('Problemin bağlamını ve önceden denediğiniz çözümleri açıklayın.'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.blue.shade700,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
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
}