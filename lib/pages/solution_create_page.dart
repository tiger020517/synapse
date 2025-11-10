import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트

class SolutionCreatePage extends StatefulWidget {
  final String problemId;
  const SolutionCreatePage({Key? key, required this.problemId})
      : super(key: key);

  @override
  _SolutionCreatePageState createState() => _SolutionCreatePageState();
}

class _SolutionCreatePageState extends State<SolutionCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _pickedImages = []; 

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      setState(() {
        _pickedImages.addAll(images);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류: $e')),
      );
    }
  }

  Future<void> _saveSolution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final userId = supabase.auth.currentUser!.id;
      List<String> imageUrls = [];
      if (_pickedImages.isNotEmpty) {
        for (final image in _pickedImages) {
          final file = File(image.path);
          final filePath =
              'public/solutions/$userId/${widget.problemId}/${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}';

          await supabase.storage.from('solutions').upload(
                filePath,
                file,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );

          final imageUrl =
              supabase.storage.from('solutions').getPublicUrl(filePath);
          imageUrls.add(imageUrl);
        }
      }

      final newSolution = await supabase
          .from('solutions')
          .insert({
            'problem_id': widget.problemId,
            'user_id': userId,
            'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
          })
          .select('id')
          .single();

      final newSolutionId = newSolution['id'];

      if (imageUrls.isNotEmpty) {
        final List<Map<String, dynamic>> imageRecords = [];
        for (int i = 0; i < imageUrls.length; i++) {
          imageRecords.add({
            'solution_id': newSolutionId,
            'image_url': imageUrls[i],
            'order': i, 
          });
        }
        await supabase.from('solution_images').insert(imageRecords);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해설지가 성공적으로 등록되었습니다!')),
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
        title: Text('새 해설지 등록'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSolution,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: '해설지 제목'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '제목은 필수입니다.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(labelText: '텍스트 설명'),
                    maxLines: 5,
                  ),
                  SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: Icon(Icons.add_photo_alternate_outlined),
                    label: Text('사진 추가하기'),
                  ),
                  SizedBox(height: 16),
                  Text('선택된 사진 (${_pickedImages.length}개)', style: Theme.of(context).textTheme.labelLarge),
                  Container(
                    height: 120,
                    child: _pickedImages.isEmpty
                        ? Center(child: Text('선택된 사진이 없습니다.'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.file(
                                  File(_pickedImages[index].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}