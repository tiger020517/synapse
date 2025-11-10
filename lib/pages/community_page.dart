import 'package:flutter/material.dart';
import '../main.dart'; // supabase 클라이언트
import 'public_problem_detail_page.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final Stream<List<Map<String, dynamic>>> _publicProblemsStream = supabase
      .from('problems')
      .stream(primaryKey: ['id'])
      .eq('is_public', true)
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시판'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _publicProblemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                '아직 공개된 문제가 없습니다.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final problems = snapshot.data!;

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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProblemDetailPage(
                        problemId: problem['id'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}