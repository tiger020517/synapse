import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트

import 'problem_update_page.dart';
import 'solution_create_page.dart';
import 'solution_detail_page.dart'; 

class ProblemDetailPage extends StatefulWidget {
  final Map<String, dynamic> problem;
  const ProblemDetailPage({Key? key, required this.problem}) : super(key: key);

  @override
  _ProblemDetailPageState createState() => _ProblemDetailPageState();
}

class _ProblemDetailPageState extends State<ProblemDetailPage> {
  late final Stream<List<Map<String, dynamic>>> _solutionsStream;
  late final String _problemId;

  @override
  void initState() {
    super.initState();
    _problemId = widget.problem['id'];
    _solutionsStream = supabase
        .from('solutions')
        .stream(primaryKey: ['id'])
        .eq('problem_id', _problemId)
        .order('created_at', ascending: true);
  }

  void _goToUpdatePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProblemUpdatePage(problem: widget.problem),
      ),
    );
  }

  void _goToCreateSolutionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolutionCreatePage(problemId: _problemId),
      ),
    );
  }

  void _goToSolutionDetailPage(Map<String, dynamic> solution) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolutionDetailPage(solution: solution),
      ),
    );
  }

  Widget _buildKeywords(List<dynamic>? keywords) {
    if (keywords == null || keywords.isEmpty) {
      return SizedBox.shrink(); 
    }
    final keywordList = keywords.cast<String>();

    return Wrap(
      spacing: 8.0, 
      runSpacing: 4.0, 
      children: keywordList.map((keyword) {
        return Chip(
          label: Text(keyword),
          backgroundColor: Theme.of(context).chipTheme.backgroundColor?.withOpacity(0.5),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.problem['cover_image_url'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('문제 상세'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note),
            onPressed: _goToUpdatePage,
            tooltip: '문제 수정',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade800,
                      child: Icon(Icons.broken_image, size: 40),
                    );
                  },
                ),
              ),
            ),
          
          SizedBox(height: 16), // (알림 버튼이 있던 자리)

          Text(
            widget.problem['title'],
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          _buildKeywords(widget.problem['keywords']),
          SizedBox(height: 16),
          Text(
            widget.problem['description'] ?? '상세 내용 없음',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Divider(height: 40),

          Text(
            '나의 해설지',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _solutionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('오류 발생: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      '아직 등록된 해설지가 없습니다.\n아래 + 버튼으로 첫 해설지를 추가하세요!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final solutions = snapshot.data!;

              return Column(
                children: solutions.map((solution) {
                  return ListTile(
                    title: Text(solution['title']),
                    subtitle: Text(
                      solution['content'] ?? '내용 없음',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _goToSolutionDetailPage(solution),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreateSolutionPage,
        child: Icon(Icons.add_comment_outlined),
        tooltip: '새 해설지 등록',
      ),
    );
  }
}