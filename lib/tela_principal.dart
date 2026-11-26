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

  Widget _itemBarra(int index, IconData icone, IconData iconeAtivo, String label) {
    final ativo = _abaAtual == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _abaAtual = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: ativo ? const Color(0xFF682BD7) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: ativo
                ? Border.all(color: const Color(0xFF9D6BFF), width: 1.2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ativo ? iconeAtivo : icone,
                color: ativo ? Colors.white : const Color(0xFFD8B4FE),
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ativo ? Colors.white : const Color(0xFFD8B4FE),
                  fontSize: 11,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13072E),
      body: _construirAba(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A3C),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF9D6BFF).withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _itemBarra(0, Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 'Tarefas'),
                _itemBarra(1, Icons.timer_outlined, Icons.timer_rounded, 'Foco'),
                _itemBarra(2, Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'Ranking'),
                _itemBarra(3, Icons.groups_outlined, Icons.groups_rounded, 'Feed'),
                _itemBarra(4, Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}