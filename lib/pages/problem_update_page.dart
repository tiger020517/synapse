import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트

class ProblemUpdatePage extends StatefulWidget {
  final Map<String, dynamic> problem;
  const ProblemUpdatePage({Key? key, required this.problem}) : super(key: key);

  @override
  _ProblemUpdatePageState createState() => _ProblemUpdatePageState();
}

class _ProblemUpdatePageState extends State<ProblemUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _keywordsController;
  bool _isLoading = false;
  late bool _isPublic;

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedCoverImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.problem['title']);
    _descriptionController =
        TextEditingController(text: widget.problem['description'] ?? '');
    final keywordsList = (widget.problem['keywords'] as List<dynamic>?)
        ?.cast<String>() ?? [];
    _keywordsController = TextEditingController(text: keywordsList.join(', '));
    _isPublic = widget.problem['is_public'] ?? false;
    _existingImageUrl = widget.problem['cover_image_url'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _pickedCoverImage = image; 
        if (image != null) {
          _existingImageUrl = null;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류: $e')),
        );
      }
    }
  }

  void _removeCoverImage() {
    setState(() {
      _pickedCoverImage = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _updateProblem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      String? finalImageUrl = _existingImageUrl; 

      if (_pickedCoverImage != null) {
        final file = File(_pickedCoverImage!.path);
        final userId = supabase.auth.currentUser!.id;
        final filePath =
            'public/problem_covers/$userId/${DateTime.now().millisecondsSinceEpoch}.${_pickedCoverImage!.path.split('.').last}';

        await supabase.storage.from('problem_covers').upload(
              filePath,
              file,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );
        finalImageUrl =
            supabase.storage.from('problem_covers').getPublicUrl(filePath);
        // TODO: 기존 이미지가 있었다면 Storage에서 삭제하는 로직이 필요 (선택)
      }
      
      final keywordsList = _keywordsController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      await supabase.from('problems').update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'keywords': keywordsList,
        'is_public': _isPublic,
        'cover_image_url': finalImageUrl, // (이미지)
      }).match({'id': widget.problem['id']});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('문제를 성공적으로 수정했습니다!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 중 오류 발생: $e')),
        );
      }
    }
    setState(() { _isLoading = false; });
  }

  Widget _buildCoverImage() {
    if (_pickedCoverImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(_pickedCoverImage!.path),
          fit: BoxFit.cover,
        ),
      );
    }
    if (_existingImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            return progress == null ? child : Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.broken_image, color: Colors.grey));
          },
        ),
      );
    }
    return Center(child: Text('선택된 이미지가 없습니다.'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('문제 수정'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProblem,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text('대표 이미지', style: Theme.of(context).textTheme.labelLarge),
                    SizedBox(height: 8),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildCoverImage(),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickCoverImage,
                            icon: Icon(Icons.add_photo_alternate_outlined),
                            label: Text('이미지 변경'),
                          ),
                        ),
                        SizedBox(width: 10),
                        if (_pickedCoverImage != null || _existingImageUrl != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _removeCoverImage,
                              icon: Icon(Icons.delete_outline),
                              label: Text('이미지 제거'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: '문제 제목'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '문제 제목은 필수입니다.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: '상세 내용'),
                      maxLines: 8,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _keywordsController,
                      decoration: InputDecoration(
                        labelText: '키워드',
                        hintText: '쉼표(,)로 구분하여 입력',
                      ),
                    ),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('게시판에 공개하기'),
                      subtitle: Text('이 문제를 다른 사람들과 공유합니다.'),
                      value: _isPublic,
                      onChanged: (bool value) {
                        setState(() { _isPublic = value; });
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}