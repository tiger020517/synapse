import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // supabase 클라이언트

import 'problem_create_page.dart';
import 'problem_detail_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Stream<List<Map<String, dynamic>>> _problemsStream = supabase
      .from('problems')
      .stream(primaryKey: ['id'])
      .eq('user_id', supabase.auth.currentUser!.id)
      .order('created_at', ascending: false);

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: ${e.message}')),
      );
    }
  }

  Future<void> _deleteProblem(String problemId) async {
    try {
      await supabase.from('problems').delete().match({'id': problemId});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문제를 삭제했습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류 발생: $e')),
      );
    }
  }

  void _goToCreatePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProblemCreatePage()),
    );
  }

  void _goToDetailPage(Map<String, dynamic> problem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProblemDetailPage(problem: problem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 문제 목록'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _problemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final problems = snapshot.data!;
            if (problems.isEmpty) {
              return Center(
                child: Text(
                  '아직 등록된 문제가 없습니다.\n아래 + 버튼을 눌러 새 문제를 등록해 보세요!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            }
            return ListView.builder(
              itemCount: problems.length,
              itemBuilder: (context, index) {
                final problem = problems[index];
                final imageUrl = problem['cover_image_url']; // (이미지)

                return ListTile(
                  leading: CircleAvatar( // (이미지)
                    radius: 25,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: (imageUrl != null)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null)
                        ? Icon(Icons.lightbulb_outline, color: Colors.white)
                        : null,
                  ),
                  title: Text(problem['title']),
                  subtitle: Text(
                    problem['description'] ?? '내용 없음',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _goToDetailPage(problem),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('삭제 확인'),
                          content: Text('"${problem['title']}" 문제를 정말 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                _deleteProblem(problem['id']);
                                Navigator.pop(context);
                              },
                              child: Text('삭제', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreatePage,
        child: Icon(Icons.add),
        tooltip: '새 문제 등록',
      ),
    );
  }
}