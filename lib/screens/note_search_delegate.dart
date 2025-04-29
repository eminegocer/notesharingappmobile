// lib/screens/note_search_delegate.dart
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'home_screen.dart'; // NoteCard'ı kullanmak için

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
      // Kullanıcıya arama yapması için bir ipucu ve sonuçları gösterelim.
      return FutureBuilder<List<Note>>(
         future: _fetchSuggestionsOnDemand(query), // Sonuçları getirir
         builder: (context, snapshot) {
            if (query.isEmpty) return _buildEmptySuggestions();

            // Yükleniyor durumu (sadece sorgu değiştiyse ve son arama değilse)
            if (snapshot.connectionState == ConnectionState.waiting && query != _lastSearchTerm) {
               return const Center(child: CircularProgressIndicator());
            }
            // Hata durumu
            if (snapshot.hasError) {
               return Center(child: Text('Arama sırasında hata: ${snapshot.error}'));
            }
            // Sonuç yok durumu
             if (!snapshot.hasData || snapshot.data!.isEmpty) {
               return Center(child: Text('"$query" için sonuç bulunamadı.'));
            }

            // Başarılı sonuç durumu
            final results = snapshot.data!;
            _suggestions = results; // Sonuçları öneri olarak sakla
             _lastSearchTerm = query; // Son başarılı aramayı kaydet

            // Sonuçları liste olarak göster
            return ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final note = results[index];
                // Sonuçları tıklanabilir yapıp delegate'i kapatabiliriz
                return ListTile(
                   leading: Icon(Icons.note_outlined), // Daha uygun bir ikon
                   title: Text(note.title),
                   subtitle: Text(
                      note.content, // İçeriği gösterelim
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                   ),
                   onTap: () {
                      // Tıklanan öneriyle aramayı tamamla
                      query = note.title; // Tıklanan notun başlığını sorgu yap (isteğe bağlı)
                      close(context, query.trim()); // Delegate'i kapat ve terimi döndür
                   },
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