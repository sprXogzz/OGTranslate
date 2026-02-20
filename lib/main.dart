import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const TranslateApp());
}

class TranslateApp extends StatefulWidget {
  const TranslateApp({super.key});

  @override
  State<TranslateApp> createState() => _TranslateAppState();
}

class _TranslateAppState extends State<TranslateApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final isDark = prefs.getBool('isDarkMode');
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    });
  }

  void toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      prefs.setBool('isDarkMode', isDark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oğuz Translate',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent, brightness: Brightness.dark),
      themeMode: _themeMode,
      home: TranslateHomePage(onThemeChanged: toggleTheme),
    );
  }
}

class TranslateHomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const TranslateHomePage({super.key, required this.onThemeChanged});

  @override
  State<TranslateHomePage> createState() => _TranslateHomePageState();
}

class _TranslateHomePageState extends State<TranslateHomePage> {
  final GoogleTranslator translator = GoogleTranslator();
  final FlutterTts flutterTts = FlutterTts(); 
  
  String translatedText = "Çeviri burada görünecek";
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;

  String sourceLanguage = 'tr';
  String targetLanguage = 'en';

  final Map<String, String> languages = {
    'tr': 'Türkçe', 'en': 'İngilizce', 'de': 'Almanca', 
    'fr': 'Fransızca', 'es': 'İspanyolca', 'it': 'İtalyanca', 'ru': 'Rusça',
  };

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _speak(String text, String languageCode) async {
    if (text.isEmpty || text == "Çeviri burada görünecek") return;
    if (languageCode == 'tr') return;

    await flutterTts.stop();
    
    await flutterTts.setSpeechRate(0.7); 
    await flutterTts.setLanguage(languageCode);
    await flutterTts.setPitch(1.0); 
    await flutterTts.speak(text);
  }

  void swapLanguages() {
    setState(() {
      String tempLang = sourceLanguage;
      sourceLanguage = targetLanguage;
      targetLanguage = tempLang;

      if (translatedText != "Çeviri burada görünecek" && translatedText.isNotEmpty) {
        _controller.text = translatedText;
        translatedText = "Çeviri bekleniyor...";
      }
    });
  }

  void translateText() async {
    if (isLoading || _controller.text.trim().isEmpty) return;

    setState(() => isLoading = true);

    bool hasInternet = await _checkConnection();
    
    if (!hasInternet) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İnternet bağlantısı yok! Lütfen kontrol edin."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; 
    }

    try {
      var translation = await translator.translate(
        _controller.text, from: sourceLanguage, to: targetLanguage,
      );
      setState(() => translatedText = translation.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Çeviri sırasında bir hata oluştu.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Oğuz Translate", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeChanged(!isDark),
          ),
        ],
        backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 5,
                        maxLength: 2000,
                        onChanged: (text) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Metni buraya yazın...', 
                          border: InputBorder.none,
                          counterStyle: TextStyle(fontSize: 12),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (sourceLanguage != 'tr')
                            IconButton(
                              icon: const Icon(Icons.volume_up, size: 20),
                              onPressed: () => _speak(_controller.text, sourceLanguage),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageDropdown(sourceLanguage, (val) => setState(() => sourceLanguage = val!)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton.filledTonal(onPressed: isLoading ? null : swapLanguages, icon: const Icon(Icons.swap_horiz)),
                    ),
                    _buildLanguageDropdown(targetLanguage, (val) => setState(() => targetLanguage = val!)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : translateText, 
                  icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.translate),
                  label: Text(isLoading ? "Kontrol ediliyor..." : "Çevir"),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                ),
              ),
              const SizedBox(height: 24),
              if (translatedText != "Çeviri burada görünecek")
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("SONUÇ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                            Row(
                              children: [
                                if (targetLanguage != 'tr')
                                  IconButton(
                                    icon: const Icon(Icons.volume_up, size: 20, color: Colors.blueAccent),
                                    onPressed: () => _speak(translatedText, targetLanguage),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: translatedText));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Panoya kopyalandı!")));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(translatedText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              // imza satırı ogi
              const SizedBox(height: 32),
              Text(
                "Made by Oğuz Rahmet Şevik",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(String value, Function(String?) onChanged) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(15),
      onChanged: isLoading ? null : onChanged,
      items: languages.entries.map((dil) => DropdownMenuItem(value: dil.key, child: Text(dil.value))).toList(),
    );
  }
}