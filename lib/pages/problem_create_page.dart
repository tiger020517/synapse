import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트

class ProblemCreatePage extends StatefulWidget {
  @override
  _ProblemCreatePageState createState() => _ProblemCreatePageState();
}

class _ProblemCreatePageState extends State<ProblemCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keywordsController = TextEditingController();

  bool _isLoading = false;
  bool _isPublic = false;
  
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedCoverImage;

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
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류: $e')),
        );
      }
    }
  }

  Future<void> _saveProblem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final userId = supabase.auth.currentUser!.id;
      String? coverImageUrl; 

      if (_pickedCoverImage != null) {
        final file = File(_pickedCoverImage!.path);
        final filePath =
            'public/problem_covers/$userId/${DateTime.now().millisecondsSinceEpoch}.${_pickedCoverImage!.path.split('.').last}';

        await supabase.storage.from('problem_covers').upload(
              filePath,
              file,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );

        coverImageUrl =
            supabase.storage.from('problem_covers').getPublicUrl(filePath);
      }

      final keywordsList = _keywordsController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      await supabase.from('problems').insert({
        'user_id': userId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'keywords': keywordsList,
        'is_public': _isPublic,
        'cover_image_url': coverImageUrl, // (이미지)
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('문제가 성공적으로 등록되었습니다!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류 발생: $e')),
        );
      }
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새 문제 등록'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProblem,
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
                    Text('대표 이미지 (선택)', style: Theme.of(context).textTheme.labelLarge),
                    SizedBox(height: 8),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _pickedCoverImage == null
                          ? Center(child: Text('선택된 이미지가 없습니다.'))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_pickedCoverImage!.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickCoverImage,
                      icon: Icon(Icons.add_photo_alternate_outlined),
                      label: Text('갤러리에서 이미지 선택'),
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: '문제 제목',
                        hintText: '해결하고 싶은 문제를 한 줄로 요약하세요.',
                      ),
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
                      decoration: InputDecoration(
                        labelText: '상세 내용',
                        hintText: '문제의 배경, 현재 상황 등을 자유롭게 적어주세요.',
                      ),
                      maxLines: 8,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _keywordsController,
                      decoration: InputDecoration(
                        labelText: '키워드',
                        hintText: '쉼표(,)로 구분하여 입력 (예: 마케팅, 효율, 광고)',
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