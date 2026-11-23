import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_principal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://btaydrfuzbyaotfbkamr.supabase.co',
publishableKey: 'sb_publishable_gZhHXFdtCuB6ZvHW7J4fjQ_6KLuPu5B',  );

  runApp(const BeProudApp());
}

final supabase = Supabase.instance.client;

class BeProudApp extends StatelessWidget {
  const BeProudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeProud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF160D28),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          surface: Color(0xFF251742),
        ),
        fontFamily: 'Roboto',
      ),
      home: supabase.auth.currentUser != null
          ? const TelaPrincipal()
          : const TelaLogin(),
    );
  }
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _modoCadastro = false;
  bool _carregando = false;

  Future<void> _autenticar() async {
    setState(() => _carregando = true);
    try {
      final email = _emailController.text.trim();
      final senha = _senhaController.text.trim();

      if (_modoCadastro) {
        final nome = _nomeController.text.trim();
        if (nome.isEmpty) throw 'Digite seu nome para criar a conta.';

        final res = await supabase.auth.signUp(email: email, password: senha);
        if (res.user != null) {
          await supabase.from('perfis').insert({
            'id': res.user!.id,
            'nome': nome,
            'email': email,
          });
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: senha);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TelaPrincipal()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.bolt_rounded, size: 64, color: Color(0xFFA78BFA)),
                const SizedBox(height: 12),
                const Text(
                  'BeProud',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use seu celular a seu favor, nÃ£o como seu inimigo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFFE2D9F3)),
                ),
                const SizedBox(height: 32),
                if (_modoCadastro) ...[
                  TextField(
                    controller: _nomeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _estiloInput('Seu nome', Icons.person_outline),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _estiloInput('E-mail', Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _estiloInput('Senha (mÃ­n. 6 caracteres)', Icons.lock_outline),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _carregando ? null : _autenticar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _modoCadastro ? 'Criar Conta' : 'Entrar',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _modoCadastro = !_modoCadastro),
                  child: Text(
                    _modoCadastro
                        ? 'JÃ¡ tem conta? FaÃ§a login'
                        : 'NÃ£o tem conta? Cadastre-se agora',
                    style: const TextStyle(color: Color(0xFFE2D9F3)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _estiloInput(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFE2D9F3)),
      prefixIcon: Icon(icone, color: const Color(0xFFA78BFA)),
      filled: true,
      fillColor: const Color(0xFF251742),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
