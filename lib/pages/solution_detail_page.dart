import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트
import 'solution_update_page.dart';

class SolutionDetailPage extends StatefulWidget {
  final Map<String, dynamic> solution;
  const SolutionDetailPage({Key? key, required this.solution}) : super(key: key);

  @override
  _SolutionDetailPageState createState() => _SolutionDetailPageState();
}

class _SolutionDetailPageState extends State<SolutionDetailPage> {
  late final Future<List<Map<String, dynamic>>> _imagesFuture;
  late final String _solutionId;

  @override
  void initState() {
    super.initState();
    _solutionId = widget.solution['id'];
    _imagesFuture = _fetchImages();
  }

  Future<List<Map<String, dynamic>>> _fetchImages() async {
    try {
      final data = await supabase
          .from('solution_images')
          .select()
          .eq('solution_id', _solutionId)
          .order('order', ascending: true);
      return data;
    } catch (e) {
      throw Exception('이미지 로딩 실패: $e');
    }
  }

  Future<void> _deleteSolution() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('해설지 삭제'),
          content: Text('"${widget.solution['title']}" 해설지를 정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await supabase.from('solutions').delete().match({'id': _solutionId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('해설지를 삭제했습니다.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 중 오류 발생: $e')),
          );
        }
      }
    }
  }

  void _goToUpdatePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // 현재 'solution' 데이터를 들고 수정 페이지로 이동
        builder: (context) => SolutionUpdatePage(solution: widget.solution),
      ),
    ).then((_) {
      // 수정 페이지에서 돌아왔을 때, 현재 페이지의 데이터를 새로고침합니다.
      // (특히 이미지가 변경되었을 수 있으므로)
      setState(() {
        _imagesFuture = _fetchExistingImages();
      });
    });
  }

  Future<List<Map<String, dynamic>>> _fetchExistingImages() async {
    try {
      final data = await supabase
          .from('solution_images')
          .select()
          .eq('solution_id', _solutionId)
          .order('order', ascending: true);
      return data;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 로딩 실패: $e')),
        );
      }
      return []; // 오류 발생 시 빈 리스트 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.solution['title'] ?? '해설지 상세'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _goToUpdatePage,
            tooltip: '해설지 수정',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: _deleteSolution,
            tooltip: '해설지 삭제',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            widget.solution['title'],
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          Text(
            widget.solution['content'] ?? '상세 내용 없음',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Divider(height: 40),
          Text(
            '첨부된 사진',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _imagesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('오류: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('첨부된 사진이 없습니다.'),
                  ),
                );
              }

              final images = snapshot.data!;
              return Column(
                children: images.map((image) {
                  final imageUrl = image['image_url'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.network(
                      imageUrl,
                      loadingBuilder: (context, child, progress) {
                        return progress == null
                            ? child
                            : Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
