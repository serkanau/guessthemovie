import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/route_transitions.dart';
import 'main_menu_screen.dart';

class UserEntryScreen extends StatefulWidget {
  const UserEntryScreen({super.key});

  @override
  State<UserEntryScreen> createState() => _UserEntryScreenState();
}

class _UserEntryScreenState extends State<UserEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService().signInAnonymouslyAndCreateProfile(_nameCtrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(const MainMenuScreen()));
    } catch (e) {
      setState(() => _error = 'Kayıt sırasında hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoş geldin')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Oyuna başlamadan önce adını yaz lütfen.'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'İsim',
                      border: OutlineInputBorder(),
                      counterText: '', // maxLength sayacını gizlemek için
                    ),
                    maxLength: 24,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'İsim zorunlu';
                      if (t.length < 2) return 'Biraz daha uzun bir isim';
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.login),
                      label: const Text('Devam Et'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
