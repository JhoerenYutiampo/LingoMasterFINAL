import 'dart:convert';
import 'package:googleapis/speech/v1.dart' as speech;
import 'package:googleapis/speech/v1.dart';
import 'package:googleapis/translate/v3.dart' as translate;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:string_similarity/string_similarity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingomaster_final/service/auth_service.dart';

class SpeechService {
  final _scopes = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/speech',
    'https://www.googleapis.com/auth/cloud-translation'
  ];
  late speech.SpeechApi _speechApi;
  late translate.TranslateApi _translateApi;
  final _auth = AuthService();
  bool _initialized = false;

  SpeechService() {
    _initApis();
  }

  Future<void> _initApis() async {
    const serviceAccountKey = r'''
    {
      
    }''';

    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountKey));
      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      _speechApi = speech.SpeechApi(client);
      _translateApi = translate.TranslateApi(client);
      _initialized = true;
      print('APIs initialized successfully.');
    } catch (e) {
      print('Error during API initialization: $e');
      if (e is DetailedApiRequestError) {
        print('Detailed error: ${e.message}');
      } else {
        print('Client error:');
      }
    }
  }

  Future<String> speechToText(String audioUrl) async {
    if (!_initialized) {
      return 'Error: APIs not initialized';
    }

    final response = await http.get(Uri.parse(audioUrl));
    final audioBytes = base64.encode(response.bodyBytes);

    final request = speech.RecognizeRequest(
      audio: speech.RecognitionAudio(content: audioBytes),
      config: speech.RecognitionConfig(
        encoding: 'LINEAR16',
        sampleRateHertz: 16000,
        languageCode: 'ja-JP',
      ),
    );

    try {
      final result = await _speechApi.speech.recognize(request);
      if (result.results?.isNotEmpty ?? false) {
        return result.results![0].alternatives![0].transcript ?? 'No speech recognized';
      } else {
        return 'No speech recognized';
      }
    } catch (e) {
      print('Error in speech recognition: $e');
      return 'Error in speech recognition';
    }
  }

  Future<String> translateText(String text) async {
    if (!_initialized) {
      return 'Error: APIs not initialized';
    }

    try {
      final request = translate.TranslateTextRequest(
        contents: [text],
        targetLanguageCode: 'en',
        sourceLanguageCode: 'ja',
      );
      final response = await _translateApi.projects.translateText(request, 'projects/lingo-master-c3b33');
      if (response.translations != null && response.translations!.isNotEmpty) {
        return response.translations![0].translatedText ?? 'Translation error';
      } else {
        return 'Translation error';
      }
    } catch (e) {
      print('Error in translation: $e');
      return 'Error in translation';
    }
  }

  double scoreTranslation(String actual, String expected) {
    return actual.similarityTo(expected);
  }

  Future<void> saveAttempt(String audioUrl, String japaneseText, String englishText, double score, String expectedEnglish) async {
    if (!_initialized) {
      print('APIs not initialized yet.');
      return;
    }

    await FirebaseFirestore.instance.collection('attempts').add({
      'userId': _auth.currentUser!.uid,
      'audioUrl': audioUrl,
      'japaneseText': japaneseText,
      'englishTranslation': englishText,
      'expectedEnglish': expectedEnglish,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> getTestAudioUrls() async {
    if (!_initialized) {
      print('APIs not initialized yet.');
      return [];
    }

    final snapshot = await FirebaseFirestore.instance.collection('test_audios').get();
    return snapshot.docs.map((doc) => doc['url'] as String).toList();
  }
}
