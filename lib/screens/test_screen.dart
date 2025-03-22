import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/connectivity_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  String _testResult = 'Henüz test yapılmadı';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Bağlantı test ediliyor...';
    });

    try {
      // İnternet bağlantısını kontrol et
      final hasConnection = await _connectivityService.checkInternetConnection();
      if (!hasConnection) {
        setState(() {
          _testResult = 'İnternet bağlantısı yok!';
          _isLoading = false;
        });
        return;
      }

      // Backend'e test isteği gönder
      try {
        final response = await _apiService.login('test@test.com', 'test123');
        setState(() {
          _testResult = 'Backend bağlantısı başarılı!\nYanıt: $response';
        });
      } catch (e) {
        setState(() {
          _testResult = 'Backend bağlantısı başarısız!\nHata: $e';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Bağlantı Testi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Bağlantıyı Test Et'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 