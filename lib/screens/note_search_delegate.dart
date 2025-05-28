// lib/screens/note_search_delegate.dart
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import './home_screen.dart'; // NoteCard'ı kullanmak için

// SearchDelegate<String?>: Kullanıcı aramayı tamamladığında veya iptal ettiğinde.
class NoteSearchDelegate extends SearchDelegate<String?> {
  final ApiService apiService;
  final TokenService tokenService;
  List<Note>? _suggestions; // Arama önerilerini tutmak için
  String? _lastSearchTerm; // Son başarılı aramayı tutmak için

  NoteSearchDelegate({required this.apiService, required this.tokenService});

  // Arama çubuğunun sağındaki aksiyonlar (örn: temizle butonu)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        tooltip: 'Temizle',
        onPressed: () {
          query = ''; // Arama çubuğunu temizle
          _suggestions = null; // Önerileri temizle
          showSuggestions(context); // Öneri görünümünü güncelle (boş gösterecek)
        },
      ),
    ];
  }

  // Arama çubuğunun solundaki ikon (örn: geri butonu)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Geri',
      onPressed: () {
        close(context, null); // Delegate'i kapat ve null döndür (iptal)
      },
    );
  }

  // Kullanıcı aramayı gönderdiğinde (örn: klavyede Enter'a bastığında) çağrılır
  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (query.trim().isNotEmpty && query != _lastSearchTerm) {
        close(context, query.trim());
      }
    });

    // Enter'a basılana kadar öneri görünümünü veya yükleniyoru göster.
     return _buildSuggestionList();
  }

  // Kullanıcı arama çubuğuna bir şeyler yazdıkça çağrılır
  @override
  Widget buildSuggestions(BuildContext context) {
     if (query.isEmpty) {
       return _buildEmptySuggestions(); // Boşsa özel mesaj
     }
     // API'yi burada çağırmak yerine, sadece sonuçlar görünümünü gösterelim.
     // API çağrısı buildResults tetiklendiğinde HomeScreen'de yapılacak.
     return _buildSuggestionList(); // Mevcut önerileri veya yükleniyoru göster
  }

   // Önerileri/Sonuçları listelemek için yardımcı widget
   Widget _buildSuggestionList() {
      return FutureBuilder<List<Note>>(
         future: _fetchSuggestionsOnDemand(query),
         builder: (context, snapshot) {
            if (query.isEmpty) return _buildEmptySuggestions();
            if (snapshot.connectionState == ConnectionState.waiting && query != _lastSearchTerm) {
               return const Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     CircularProgressIndicator(),
                     SizedBox(height: 16),
                     Text('Aranıyor...'),
                   ],
                 ),
               );
            }
            if (snapshot.hasError) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, color: Colors.red, size: 48),
                     SizedBox(height: 16),
                     Text('Arama sırasında hata oluştu:'),
                     Text(snapshot.error.toString(), textAlign: TextAlign.center),
                     SizedBox(height: 16),
                     ElevatedButton.icon(
                       icon: Icon(Icons.refresh),
                       label: Text('Tekrar Dene'),
                       onPressed: () {
                         _suggestions = null;
                         _lastSearchTerm = null;
                         showSuggestions(context);
                       },
                     ),
                   ],
                 ),
               );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.search_off_rounded, color: Colors.grey, size: 48),
                     SizedBox(height: 16),
                     Text('"$query" için sonuç bulunamadı.'),
                     SizedBox(height: 8),
                     Text('Farklı bir terimle aramayı deneyin.'),
                   ],
                 ),
               );
            }
            final results = snapshot.data!;
            _suggestions = results;
            _lastSearchTerm = query;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final note = results[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NoteCard(note: note, searchTerm: query),
                );
              },
            );
         },
      );
   }

   // Arama çubuğu boşken gösterilecek widget
   Widget _buildEmptySuggestions() {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 8),
            Text('Okul, bölüm, ders adı veya içerik ile arayın.'),
          ],
        ),
      );
   }

   // Gerekli olduğunda API çağrısı yapacak fonksiyon
    Future<List<Note>> _fetchSuggestionsOnDemand(String currentQuery) async {
       final token = await tokenService.getToken();
       if (token == null) return []; // Token yoksa arama yapma
        if (currentQuery.trim().isEmpty) return []; // Sorgu boşsa arama yapma

       // Eğer mevcut sorgu son başarılı arama ile aynıysa ve öneriler varsa, API'yi tekrar çağırmak yerine saklananları kullan
       // Bu, kullanıcı Enter'a bastıktan sonra suggestions görünümüne döndüğünde tekrar yüklenmeyi engeller.
       if (currentQuery == _lastSearchTerm && _suggestions != null) {
         return _suggestions!;
       }
       try {
          // API'den sonuçları al
          return await apiService.searchNotes(token, currentQuery);
       } catch (e) {
          print("Suggestion fetch error: $e");
          return []; // Hata durumunda boş öneri
       }
    }

} 