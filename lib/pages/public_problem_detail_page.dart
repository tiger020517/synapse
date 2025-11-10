import 'package:flutter/material.dart';
import '../main.dart'; // supabase 클라이언트

class PublicProblemDetailPage extends StatefulWidget {
  final String problemId; 
  const PublicProblemDetailPage({Key? key, required this.problemId})
      : super(key: key);

  @override
  _PublicProblemDetailPageState createState() => _PublicProblemDetailPageState();
}

class _PublicProblemDetailPageState extends State<PublicProblemDetailPage> {
  late final Future<Map<String, dynamic>> _problemDetailsFuture;

  @override
  void initState() {
    super.initState();
    _problemDetailsFuture = _fetchProblemDetails();
  }

  Future<Map<String, dynamic>> _fetchProblemDetails() async {
    try {
      final data = await supabase
          .from('problems')
          .select('*, solutions(*, solution_images(*))') 
          .eq('id', widget.problemId)
          .single(); 
      return data;
    } catch (e) {
      throw Exception('데이터 로딩 실패: $e');
    }
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
        return Chip(label: Text(keyword));
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('문제 살펴보기'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _problemDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('문제를 찾을 수 없습니다.'));
          }

          final problem = snapshot.data!;
          final solutions = (problem['solutions'] as List<dynamic>?) ?? [];
          final imageUrl = problem['cover_image_url']; // (이미지)

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              
              if (imageUrl != null) // (이미지)
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

              Text(
                problem['title'],
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16),
              _buildKeywords(problem['keywords']),
              SizedBox(height: 16),
              Text(
                problem['description'] ?? '상세 내용 없음',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Divider(height: 40),

              Text(
                '해설지 목록 (${solutions.length}개)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),

              if (solutions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: Text('등록된 해설지가 없습니다.')),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: solutions.map((solution) {
                    final solutionImages =
                        (solution['solution_images'] as List<dynamic>?) ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              solution['title'],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            Text(solution['content'] ?? '내용 없음'),
                            SizedBox(height: 12),
                            
                            if (solutionImages.isNotEmpty)
                              Container(
                                height: 120, 
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: solutionImages.length,
                                  itemBuilder: (context, index) {
                                    final imageUrl =
                                        solutionImages[index]['image_url'];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Image.network(
                                        imageUrl,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          return progress == null
                                              ? child
                                              : Center(child: CircularProgressIndicator());
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(width: 100, color: Colors.grey[300], child: Icon(Icons.broken_image));
                                        },
                                      ),
                                    );
                                  },
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}