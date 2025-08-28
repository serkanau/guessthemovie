import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../utils/route_transitions.dart';
import 'game_screen.dart';

import 'dart:convert'; //test için. daha sonra sil
import 'package:flutter/services.dart' show rootBundle; //test için. daha sonra sil


class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});


  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();

}
class _MainMenuScreenState extends State<MainMenuScreen> {
  String _name = '';
  int _played = 0;
  int _correct = 0;

  List<Map<String, dynamic>> _achievements = []; //test için. daha sonra sil

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snap.exists) {
      final map = snap.value as Map;
      setState(() {
        _name = (map['name'] ?? '') as String;
        final stats = (map['stats'] ?? {}) as Map;
        _played = (stats['gamesPlayed'] ?? 0) as int;
        _correct = (stats['correctCount'] ?? 0) as int;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guess The Movie')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Merhaba, ${_name.isEmpty ? 'Oyuncu' : _name}!', style:
                Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Oynanan: $_played • Doğru: $_correct'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      slideUpRoute(const GameScreen())),
                  icon: const Icon(Icons.play_arrow),

                  label: const Text('Play'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
