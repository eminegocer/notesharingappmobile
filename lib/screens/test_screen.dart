import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/note.dart';
import '../services/token_service.dart';
import './note_detail_screen.dart';
import './category_screen.dart';

class TestScreen extends StatefulWidget {
  final List<dynamic> questions;
  final String token;

  const TestScreen({Key? key, required this.questions, required this.token}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int currentIndex = 0;
  List<String?> userAnswers = [];
  List<bool?> isCorrect = [];
  List<bool> answered = [];

  @override
  void initState() {
    super.initState();
    // Soru sayısı sınırı kaldırıldı, tüm sorular gösterilecek
    userAnswers = List.filled(widget.questions.length, null);
    isCorrect = List.filled(widget.questions.length, null);
    answered = List.filled(widget.questions.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[currentIndex];
    final category = q['category'] ?? '';
    final question = q['question'] ?? '';
    final choices = (q['choices'] as List?)?.cast<String>();
    final correctAnswer = q['answer'] ?? '';
    final explanation = q['explanation'] ?? '';

    if (question.isEmpty || choices == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: Text('Soru veya şıklar eksik.')),
      );
    }

    bool showResult = answered[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${currentIndex + 1}/${widget.questions.length}'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori etiketi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: const TextStyle(color: Color(0xFF3A7BD5), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 18),
            // Soru metni
            Text(
              question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Şıklar
            ...List.generate(choices.length, (i) {
              final selected = userAnswers[currentIndex] == choices[i];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Material(
                  color: selected ? Colors.blue.shade100 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: showResult
                        ? null
                        : () {
                            setState(() {
                              userAnswers[currentIndex] = choices[i];
                              answered[currentIndex] = true;
                              isCorrect[currentIndex] = choices[i].toLowerCase() == correctAnswer.toLowerCase();
                            });
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            choices[i],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Açıklama, doğru/yanlış kutusu ve butonlar şıkların hemen altında
            if (showResult) ...[
              const SizedBox(height: 18),
              if (explanation.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    explanation,
                    style: const TextStyle(color: Color(0xFF3578E5), fontSize: 15),
                  ),
                ),
              Row(
                children: [
                  Icon(
                    isCorrect[currentIndex] == true ? Icons.check_circle : Icons.cancel,
                    color: isCorrect[currentIndex] == true ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isCorrect[currentIndex] == true
                        ? 'Tebrikler, doğru cevap!'
                        : 'Yanlış cevap!',
                    style: TextStyle(
                      color: isCorrect[currentIndex] == true ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentIndex < widget.questions.length - 1)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentIndex++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showResult ? Colors.blue : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        ),
                        child: const Text('İlerle'),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: showResult ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      onPressed: () async {
                        final api = ApiService();
                        final token = widget.token;
                        final answers = <Map<String, dynamic>>[];
                        for (int i = 0; i < widget.questions.length; i++) {
                          final q = widget.questions[i];
                          answers.add({
                            'Category': q['category'] ?? '',
                            'Question': q['question'] ?? '',
                            'UserAnswer': userAnswers[i],
                            'CorrectAnswer': q['answer'] ?? '',
                          });
                        }
                        if (answers.every((a) => a['UserAnswer'] == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('En az bir soruyu cevaplamalısınız!')),
                          );
                          return;
                        }
                        try {
                          final result = await api.submitTest(token, answers);
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TestResultScreen(
                                categoryStats: result['categoryStats'] ?? result['CategoryStats'] ?? [],
                                recommendedNotes: result['recommendedNotes'] ?? result['RecommendedNotes'] ?? [],
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TestResultScreen(
                                categoryStats: [],
                                recommendedNotes: [],
                              ),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Test sonucu gönderilemedi: $e')),
                          );
                        }
                      },
                      child: const Text('Testi Bitir'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TestResultScreen extends StatelessWidget {
  final List<dynamic> categoryStats;
  final List<dynamic> recommendedNotes;

  const TestResultScreen({Key? key, required this.categoryStats, required this.recommendedNotes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Sonuçları'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başarı Oranları Kartı (Yatay scrollable, overflow korumalı)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade50,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategori Başarı Oranları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF3A7BD5))),
                    const SizedBox(height: 12),
                    if (categoryStats.isEmpty)
                      const Text('Veri yok', style: TextStyle(color: Colors.grey)),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categoryStats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final stat = categoryStats[index];
                          final category = stat['category'] ?? stat['Category'] ?? '';
                          final rate = (stat['successRate'] ?? stat['SuccessRate'] ?? 0.0).toDouble();
                          return Container(
                            width: 180,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Color(0xFF3A7BD5), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A7BD5)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: rate / 100.0,
                                  minHeight: 6,
                                  backgroundColor: Colors.blue.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A7BD5)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${rate.toStringAsFixed(1)}%',
                                  style: const TextStyle(color: Color(0xFF3A7BD5), fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Önerilen Notlar Kartı (overflow korumalı, sade kutu, kullanıcı adı kategori altına)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade50,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Size Önerilen Notlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF3A7BD5))),
                    const SizedBox(height: 12),
                    if (recommendedNotes.isEmpty)
                      const Text('Veri yok', style: TextStyle(color: Colors.grey)),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendedNotes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, i) {
                          final note = recommendedNotes[i];
                          return GestureDetector(
                            onTap: () async {
                              final apiService = ApiService();
                              final tokenService = TokenService();
                              final token = await tokenService.getToken();
                              if (token == null) return;
                              try {
                                // noteId farklı anahtarlarla gelebilir
                                final noteId = note['noteId'] ?? note['NoteId'] ?? note['id'] ?? note['Id'];
                                if (noteId == null || noteId.toString().isEmpty) return;
                                final noteJson = await apiService.getNoteById(token, noteId.toString());
                                final noteObj = Note.fromJson(noteJson);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NoteDetailScreen(note: noteObj),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Not detayına gidilemedi: $e')),
                                );
                              }
                            },
                            child: Container(
                              width: 200,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Color(0xFF3A7BD5), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    note['title'] ?? note['Title'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3578E5)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    note['content'] ?? note['Content'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      note['category'] ?? note['Category'] ?? '',
                                      style: const TextStyle(color: Color(0xFF3A7BD5), fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    note['ownerUsername'] ?? note['OwnerUsername'] ?? '',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Kapat'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const CategoryScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3A7BD5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Kategoriler Sayfasına Git'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 