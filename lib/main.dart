import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_principal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://btaydrfuzbyaotfbkamr.supabase.co',
    publishableKey: 'sb_publishable_gZhHXFdtCuB6ZvHW7J4fjQ_6KLuPu5B',
  );

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
      backgroundColor: const Color(0xFFC9B6F2), // Fundo lavanda do Figma
      body: Stack(
        children: [
          // Formas circulares roxas de fundo (igual ao protótipo)
          Positioned(
            top: -55,
            right: -65,
            child: Container(
              width: 340,
              height: 340,
              decoration: const BoxDecoration(
                color: Color(0xFF682BD7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 210,
            left: -25,
            right: -25,
            child: Container(
              height: 360,
              decoration: const BoxDecoration(
                color: Color(0xFF682BD7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 410,
            left: -60,
            right: -60,
            bottom: -100,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF682BD7),
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(420, 220),
                ),
              ),
            ),
          ),

          // Conteúdo principal da tela
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho: Ícone inclinado + Logo BeProud em 2 cores
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: -12 * math.pi / 180,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9D6BFF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFFC9B6F2),
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Be',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Proud',
                                  style: TextStyle(color: Color(0xFF9D6BFF)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Slogan
                      const Text(
                        'Seu celular a seu favor,\nnão como seu inimigo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 3 Pilares com divisórias brancas
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _itemDestaque(
                              icone: Icons.check_circle,
                              texto: 'crie tarefas\ne metas',
                            ),
                            const VerticalDivider(
                              color: Colors.white,
                              thickness: 1.5,
                              width: 16,
                            ),
                            _itemDestaque(
                              icone: Icons.bar_chart_rounded,
                              texto: 'Acompanhe sua\nprodutividade',
                            ),
                            const VerticalDivider(
                              color: Colors.white,
                              thickness: 1.5,
                              width: 16,
                            ),
                            _itemDestaque(
                              icone: Icons.groups_rounded,
                              texto: 'Compare com\nseus amigos',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Caixas de texto (Nome opcional no cadastro + E-mail + Senha)
                      if (_modoCadastro) ...[
                        TextField(
                          controller: _nomeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _estiloInput('Seu nome', Icons.person_outline),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _estiloInput('E-mail', Icons.email_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _senhaController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _estiloInput('Senha (mín. 6 caracteres)', Icons.lock_outline),
                      ),
                      const SizedBox(height: 22),

                      // Botão escuro estilo pílula do Figma ("Entrar com e-mail")
                      ElevatedButton(
                        onPressed: _carregando ? null : _autenticar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF180936),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: _carregando
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _modoCadastro ? 'Criar Conta' : 'Entrar',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Rodapé: Criar Conta ->
                      TextButton(
                        onPressed: () => setState(() => _modoCadastro = !_modoCadastro),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _modoCadastro
                                  ? 'Já tem conta? Fazer login'
                                  : 'Criar Conta',
                              style: const TextStyle(
                                color: Color(0xFFD8C7FF),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF180936),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemDestaque({required IconData icone, required String texto}) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icone,
            size: 46,
            color: const Color(0xFF9D6BFF),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _estiloInput(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFE2D9F3)),
      prefixIcon: Icon(icone, color: const Color(0xFFC9B6F2)),
      filled: true,
      fillColor: const Color(0xFF4B1CA6),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFF9D6BFF), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.white, width: 1.8),
      ),
    );
  }
}