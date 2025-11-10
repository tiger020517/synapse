import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트

class SolutionUpdatePage extends StatefulWidget {
  // SolutionDetailPage에서 전달받은 기존 해설지 데이터
  final Map<String, dynamic> solution;

  const SolutionUpdatePage({Key? key, required this.solution}) : super(key: key);

  @override
  _SolutionUpdatePageState createState() => _SolutionUpdatePageState();
}

class _SolutionUpdatePageState extends State<SolutionUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  
  bool _isLoading = false;
  
  // --- 이미지 관리 ---
  final ImagePicker _picker = ImagePicker();
  
  // 1. DB에서 불러온 기존 이미지 목록 (Map 형태)
  List<Map<String, dynamic>> _existingImages = []; 
  
  // 2. 갤러리에서 새로 선택한 이미지 목록 (XFile 형태)
  List<XFile> _newlyPickedImages = [];
  
  // 3. 삭제하기로 표시된 기존 이미지의 ID 목록 (String 형태)
  List<String> _removedImageIds = []; 
  // --------------------

  @override
  void initState() {
    super.initState();
    // 1. 텍스트 컨트롤러 초기화
    _titleController = TextEditingController(text: widget.solution['title']);
    _contentController = TextEditingController(text: widget.solution['content'] ?? '');

    // 2. 기존 이미지 목록 불러오기 시작
    _fetchExistingImages();
  }

  /// DB의 'solution_images' 테이블에서 이 해설지에 연결된 이미지들을 가져옴
  Future<void> _fetchExistingImages() async {
    setState(() { _isLoading = true; });
    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('solution_images')
          .select()
          .eq('solution_id', widget.solution['id'])
          .order('order', ascending: true);
      
      if (mounted) {
        setState(() {
          _existingImages = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기존 이미지 로딩 실패: $e')),
        );
      }
    }
    setState(() { _isLoading = false; });
  }

  /// 갤러리에서 여러 이미지 '추가' 선택
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      setState(() {
        _newlyPickedImages.addAll(images);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류: $e')),
      );
    }
  }

  /// (핵심) 수정 사항 저장
  Future<void> _updateSolution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    final userId = supabase.auth.currentUser!.id;
    final problemId = widget.solution['problem_id'];
    final solutionId = widget.solution['id'];

    try {
      // --- 1. 텍스트 정보 업데이트 ---
      await supabase.from('solutions').update({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
      }).match({'id': solutionId});

      // --- 2. 이미지 삭제 처리 ---
      if (_removedImageIds.isNotEmpty) {
        // 2-1. DB에서 레코드 삭제
      await supabase.from('solution_images').delete().inFilter('id', _removedImageIds);        
        // 2-2. (선택) Storage에서도 실제 파일 삭제 (URL 파싱 필요 - 지금은 생략)
        // ... (TODO: Storage 파일 삭제 로직) ...
      }

      // --- 3. 새 이미지 추가 처리 ---
      if (_newlyPickedImages.isNotEmpty) {
        List<Map<String, dynamic>> newImageRecords = [];
        
        // 현재 이미지 중 가장 큰 'order' 값을 찾습니다 (순서 유지를 위해)
        int maxOrder = _existingImages.map((img) => img['order'] as int).fold(0, (max, e) => e > max ? e : max);

        for (int i = 0; i < _newlyPickedImages.length; i++) {
          final image = _newlyPickedImages[i];
          final file = File(image.path);
          final filePath =
              'public/solutions/$userId/$problemId/${DateTime.now().millisecondsSinceEpoch}_${i}.${image.path.split('.').last}';

          // 3-1. Storage에 업로드
          await supabase.storage.from('solutions').upload(
                filePath,
                file,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              );

          // 3-2. Public URL 가져오기
          final imageUrl = supabase.storage.from('solutions').getPublicUrl(filePath);
          
          // 3-3. DB에 삽입할 레코드 준비
          newImageRecords.add({
            'solution_id': solutionId,
            'image_url': imageUrl,
            'order': maxOrder + i + 1, // 순서를 기존 이미지 뒤에 붙임
          });
        }
        
        // 3-4. DB에 새 이미지 레코드 삽입
        await supabase.from('solution_images').insert(newImageRecords);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해설지를 성공적으로 수정했습니다!')),
        );
        Navigator.pop(context); // SolutionDetailPage로 복귀
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('해설지 수정'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _updateSolution,
          )
        ],
      ),
      body: _isLoading
          ? Center(
                child: Column( // Column으로 감싸줍니다.
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16), // 인디케이터와 텍스트 사이 간격
                    Text('데이터 로딩 중...'), // Text 위젯을 따로 사용
                  ],
                ),
              )
         : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- 1. 텍스트 폼 ---
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
                  
                  // --- 2. 기존 이미지 목록 (삭제 가능) ---
                  Text('기존 사진', style: Theme.of(context).textTheme.labelLarge),
                  if (_existingImages.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('기존 사진이 없습니다.'),
                    ))
                  else
                    _buildImageGrid(
                      imageWidgets: _existingImages.map((image) {
                        return Stack(
                          alignment: Alignment.topRight,
                          children: [
                            // 기존 이미지
                            Image.network(
                              image['image_url'],
                              width: 100, height: 100, fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                return progress == null ? child : Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(width: 100, height: 100, color: Colors.grey.shade800, child: Icon(Icons.broken_image));
                              },
                            ),
                            // 삭제 버튼
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.redAccent),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  // 삭제 목록에 ID 추가
                                  _removedImageIds.add(image['id'] as String);
                                  // 화면에서 즉시 제거
                                  _existingImages.removeWhere((item) => item['id'] == image['id']);
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  
                  SizedBox(height: 16),

                  // --- 3. 새로 추가할 이미지 목록 (삭제 가능) ---
                  Text('새로 추가할 사진 (${_newlyPickedImages.length}개)', style: Theme.of(context).textTheme.labelLarge),
                  if (_newlyPickedImages.isNotEmpty)
                    _buildImageGrid(
                      imageWidgets: _newlyPickedImages.map((image) {
                        return Stack(
                          alignment: Alignment.topRight,
                          children: [
                            // 새 이미지
                            Image.file(
                              File(image.path),
                              width: 100, height: 100, fit: BoxFit.cover,
                            ),
                            // 삭제 버튼
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.redAccent),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  // 화면에서 즉시 제거
                                  _newlyPickedImages.remove(image);
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),

                  SizedBox(height: 16),
                  
                  // --- 4. 사진 추가 버튼 ---
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: Icon(Icons.add_photo_alternate_outlined),
                    label: Text('사진 추가하기'),
                  ),
                ],
              ),
            ),
    );
  }

  /// 이미지 목록을 예쁘게 보여주기 위한 헬퍼 위젯
  Widget _buildImageGrid({required List<Widget> imageWidgets}) {
    return Container(
      height: 110, // GridView 높이 고정
      child: GridView.count(
        crossAxisCount: 1, // 가로 스크롤을 위한 트릭
        mainAxisSpacing: 8.0,
        scrollDirection: Axis.horizontal,
        children: imageWidgets.map((widget) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: widget,
            ),
          );
        }).toList(),
      ),
    );
  }
}