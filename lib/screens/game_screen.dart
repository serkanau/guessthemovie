import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/movie.dart';
import '../services/db_service.dart';
import '../utils/shared_prefs.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _db = DbService();
  final _focusNode = FocusNode();
  List<Movie> _all = [];
  Set<String> _seen = {};
  Movie? _current;
  int _imageIdx = 0; // 0..4
  bool _loading = true;
  String? _error;
  late Future<List<String>> _futureKeywords;

  // Autocomplete içinden gelen controller burada saklanacak
  TextEditingController? _guessCtrl;

  @override
  void initState() {
    super.initState();
    _futureKeywords = _loadKeywords();
    _init();
  }

  @override
  void dispose() {
    _guessCtrl?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<String>> _loadKeywords() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/keywords.json');
      final List<dynamic> raw = json.decode(jsonStr) as List<dynamic>;
      final list = raw.whereType<String>().toList();
      list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return list;
    } catch (e) {
      print('Error loading keywords: $e');
      return [];
    }
  }

  Future<void> _init() async {
    try {
      _seen = await SeenStore.getSeenIds();
      _all = await _db.fetchAllMovies();
      await _pickNext();
    } catch (e) {
      setState(() => _error = 'Oyun yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickNext() async {
    setState(() {
      _current = null;
      _imageIdx = 0;
    });

    final next = _db.pickRandom(_all, _seen);
    if (next == null) {
      setState(() {
        _error = 'Tüm filmleri denedin. Sıfırlayabilirsin.';
      });
      return;
    }

    setState(() {
      _current = next;
    });

    await _db.incrementMovieView(next.id);
    await SeenStore.addSeen(next.id);
    _seen.add(next.id);
  }

  String _normalize(String s) {
    final lower = s.toLowerCase();
    const repl = {
      'ı': 'i',
      'İ': 'i',
      'ğ': 'g',
      'Ğ': 'g',
      'ü': 'u',
      'Ü': 'u',
      'ş': 's',
      'Ş': 's',
      'ö': 'o',
      'Ö': 'o',
      'ç': 'c',
      'Ç': 'c'
    };
    return lower
        .split('')
        .map((c) => repl[c] ?? c)
        .join()
        .replaceAll(RegExp(r"[^a-z0-9 ]"), '')
        .trim();
  }

  Future<void> _checkGuess([String? fromSelection]) async {
    if (_current == null) return;

    final guess = _normalize(fromSelection ?? _guessCtrl?.text ?? "");
    final title = _normalize(_current!.title);
    if (guess.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (guess == title) {
      await _db.incrementMovieRight(_current!.id);
      await _db.incrementUserStats(uid, correct: true);
      if (!mounted) return;
      await _showResultDialog(correct: true);
      if (!mounted) return;
      _guessCtrl?.clear(); // textbox temizleme
      await _pickNext();
    } else {
      if (_imageIdx < (_current!.images.length - 1)) {
        setState(() {
          _imageIdx++;
        });
      } else {
        await _db.incrementUserStats(uid, correct: false);
        if (!mounted) return;
        await _showResultDialog(correct: false);
        if (!mounted) return;
        _guessCtrl?.clear();
        await _pickNext();
      }
    }
  }

  Future<void> _showResultDialog({required bool correct}) async {
    final movie = _current!;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(correct ? 'Tebrikler, bildin!' : 'Olmadı :('),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (movie.poster.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: movie.poster,
                  fit: BoxFit.cover,
                  height: 200,
                  width: 140,
                  placeholder: (c, _) => const SizedBox(
                    height: 200,
                    width: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (c, _, __) =>
                  const Icon(Icons.image_not_supported),
                ),
              ),
            const SizedBox(height: 12),
            Text(movie.title, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Devam'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Film Tahmini'),
        actions: [
          IconButton(
            tooltip: 'Sıfırla (görülen filmler)',
            onPressed: () async {
              await SeenStore.reset();
              if (!mounted) return;
              setState(() {
                _seen.clear();
              });
              await _pickNext();
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _error != null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: _pickNext,
                      child: const Text('Tekrar dene')),
                ],
              )
                  : _current == null
                  ? const Text('Yüklenecek film bulunamadı.')
                  : FutureBuilder<List<String>>(
                future: _futureKeywords,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                          'Veri yüklenemedi: ${snapshot.error}'),
                    );
                  }
                  final keywords =
                      snapshot.data ?? const <String>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ImageStage(
                          movie: _current!, index: _imageIdx),
                      const SizedBox(height: 12),
                      Text(
                        'Sahne ${_imageIdx + 1}/${_current!.images.length}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<String>(
                        optionsBuilder:
                            (TextEditingValue textEditingValue) {
                          final query =
                          textEditingValue.text.trim();
                          if (query.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          final lower = query.toLowerCase();
                          final matches = keywords.where((k) =>
                              k.toLowerCase().contains(lower));
                          return matches.take(12);
                        },
                        onSelected: (String selection) {
                          _guessCtrl?.text = selection;
                        },
                        fieldViewBuilder: (context,
                            textController,
                            focusNode,
                            onFieldSubmitted) {
                          _guessCtrl ??= textController;
                          return TextField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Bir şey yazın…',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            onSubmitted: (value) {
                              onFieldSubmitted();
                              _checkGuess();
                            },
                          );
                        },
                        optionsViewBuilder:
                            (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius:
                              BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxHeight: 300, maxWidth: 400),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option =
                                    options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      title: Text(option),
                                      onTap: () =>
                                          onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'İpucu: Yazdıkça altta öneriler açılır, birine dokunursan kutuya otomatik yazılır.',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            _checkGuess();
                            _guessCtrl?.clear(); // butona basınca temizleme
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Tahmini Gönder'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageStage extends StatelessWidget {
  final Movie movie;
  final int index;
  const _ImageStage({required this.movie, required this.index});

  @override
  Widget build(BuildContext context) {
    final url = movie.images[index];
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (c, _) =>
          const Center(child: CircularProgressIndicator()),
          errorWidget: (c, _, __) => Container(
            color: Colors.black12,
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }
}
