import 'package:flutter/material.dart';
import 'tela_tarefas.dart';
import 'tela_foco.dart';
import 'tela_ranking.dart';
import 'tela_feed.dart';
import 'tela_perfil.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _abaAtual = 0;

  Widget _construirAba() {
    switch (_abaAtual) {
      case 0:
        return const TelaTarefas();
      case 1:
        return const TelaFoco();
      case 2:
        return const TelaRanking();
      case 3:
        return const TelaFeed();
      case 4:
        return const TelaPerfil();
      default:
        return const TelaTarefas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _construirAba(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (index) => setState(() => _abaAtual = index),
        backgroundColor: const Color(0xFF251742),
        indicatorColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline, color: Color(0xFFE2D9F3)),
            selectedIcon: Icon(Icons.check_circle, color: Color(0xFFA78BFA)),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined, color: Color(0xFFE2D9F3)),
            selectedIcon: Icon(Icons.timer, color: Color(0xFFA78BFA)),
            label: 'Foco',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined, color: Color(0xFFE2D9F3)),
            selectedIcon: Icon(Icons.emoji_events, color: Color(0xFFA78BFA)),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined, color: Color(0xFFE2D9F3)),
            selectedIcon: Icon(Icons.public, color: Color(0xFFA78BFA)),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Color(0xFFE2D9F3)),
            selectedIcon: Icon(Icons.person, color: Color(0xFFA78BFA)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
