import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaFoco extends StatefulWidget {
  const TelaFoco({super.key});

  @override
  State<TelaFoco> createState() => _TelaFocoState();
}

class _TelaFocoState extends State<TelaFoco> {
  final _supabase = Supabase.instance.client;
  var _tarefasPendentes = [];
  dynamic _tarefaSelecionada;

  int _minutosEscolhidos = 25;
  int _segundosRestantes = 25 * 60;
  bool _rodando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarTarefasPendentes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarTarefasPendentes() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final dados = await _supabase
          .from('tarefas')
          .select()
          .eq('usuario_id', userId)
          .eq('concluida', false)
          .order('criada_em', ascending: false);

      if (mounted) {
        setState(() {
          _tarefasPendentes = dados;
          if (_tarefasPendentes.isNotEmpty) {
            _tarefaSelecionada = _tarefasPendentes.first;
          }
        });
      }
    } catch (_) {}
  }

  void _definirTempo(int minutos) {
    if (_rodando) return;
    setState(() {
      _minutosEscolhidos = minutos;
      _segundosRestantes = minutos * 60;
    });
  }

  void _alternarTimer() {
    if (_rodando) {
      _timer?.cancel();
      setState(() => _rodando = false);
    } else {
      setState(() => _rodando = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_segundosRestantes > 0) {
          setState(() => _segundosRestantes--);
        } else {
          _finalizarSessaoFoco();
        }
      });
    }
  }

  void _resetarTimer() {
    _timer?.cancel();
    setState(() {
      _rodando = false;
      _segundosRestantes = _minutosEscolhidos * 60;
    });
  }

  Future<void> _finalizarSessaoFoco() async {
    _timer?.cancel();
    setState(() => _rodando = false);

    final minutosFocados = ((_minutosEscolhidos * 60 - _segundosRestantes) / 60).ceil();
    final tempoRegistrar = minutosFocados > 0 ? minutosFocados : _minutosEscolhidos;

    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1. Atualiza tempo focado na tarefa selecionada (se houver)
      if (_tarefaSelecionada != null) {
        final tempoAtual = (_tarefaSelecionada['tempo_focado_minutos'] ?? 0) as int;
        await _supabase
            .from('tarefas')
            .update({'tempo_focado_minutos': tempoAtual + tempoRegistrar})
            .eq('id', _tarefaSelecionada['id']);
      }

      // 2. Soma +25 XP no perfil
      final perfil = await _supabase
          .from('perfis')
          .select('xp_semanal')
          .eq('id', userId)
          .single();

      final xpAtual = (perfil['xp_semanal'] ?? 0) as int;
      await _supabase
          .from('perfis')
          .update({'xp_semanal': xpAtual + 25})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sessão concluída! +$tempoRegistrar min registrados e +25 XP!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
      _resetarTimer();
      _carregarTarefasPendentes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar sessão: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatarRelogio(int totalSegundos) {
    final min = (totalSegundos ~/ 60).toString().padLeft(2, '0');
    final seg = (totalSegundos % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

  @override
  Widget build(BuildContext context) {
    final totalSegundos = _minutosEscolhidos * 60;
    final progresso = totalSegundos > 0 ? _segundosRestantes / totalSegundos : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF13072E), // Mesmo fundo da página inicial
      body: Stack(
        children: [
          // As duas bolas decorativas exatamente nas mesmas posições da tela inicial
          Positioned(
            top: -50,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF682BD7).withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 230,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF682BD7).withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      // Título da seção no estilo do Figma
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'Modo ',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Foco',
                              style: TextStyle(color: Color(0xFF9D6BFF)),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 22),

                      // 2. Seletor de Tarefa alvo estilizado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF281154).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFF9D6BFF).withValues(alpha: 0.55),
                            width: 1,
                          ),
                        ),
                        child: _tarefasPendentes.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bolt_rounded, color: Color(0xFF9D6BFF), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Foco livre (nenhuma tarefa pendente)',
                                      style: TextStyle(color: Color(0xFFE2D9F3), fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<dynamic>(
                                  value: _tarefaSelecionada,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF281154),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF9D6BFF),
                                  ),
                                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                                  items: _tarefasPendentes.map((t) {
                                    return DropdownMenuItem<dynamic>(
                                      value: t,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.track_changes_rounded,
                                            color: Color(0xFF9D6BFF),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              t['titulo'],
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _rodando
                                      ? null
                                      : (nova) => setState(() => _tarefaSelecionada = nova),
                                ),
                              ),
                      ),
                      const SizedBox(height: 30),

                      // 3. Círculo do Cronômetro com brilho e bordas suaves
                      Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1F0D42).withValues(alpha: 0.8),
                          border: Border.all(
                            color: const Color(0xFF9D6BFF).withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_rodando
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF682BD7))
                                  .withValues(alpha: _rodando ? 0.35 : 0.18),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 226,
                              height: 226,
                              child: CircularProgressIndicator(
                                value: progresso,
                                strokeWidth: 11,
                                strokeCap: StrokeCap.round,
                                backgroundColor: const Color(0xFF3E1E7A),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _rodando
                                      ? const Color(0xFFA78BFA)
                                      : const Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _rodando
                                      ? Icons.local_fire_department_rounded
                                      : Icons.timer_outlined,
                                  color: _rodando
                                      ? const Color(0xFFFACC15)
                                      : const Color(0xFF9D6BFF),
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatarRelogio(_segundosRestantes),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _rodando ? 'Mantenha o foco!' : 'Pronto para começar',
                                  style: const TextStyle(
                                    color: Color(0xFFD8B4FE),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4. Botões de duração rápida em estilo pílula
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [15, 25, 45].map((min) {
                          final ativo = _minutosEscolhidos == min;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => _definirTempo(min),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: ativo
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF281154).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: ativo
                                        ? const Color(0xFFD8B4FE)
                                        : const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  '$min min',
                                  style: TextStyle(
                                    color: ativo ? Colors.white : const Color(0xFFD8B4FE),
                                    fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // 5. Controles Iniciar / Pausar e Resetar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _alternarTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _rodando
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF682BD7),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(
                                  color: _rodando
                                      ? const Color(0xFFFDE68A)
                                      : const Color(0xFF9D6BFF),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            icon: Icon(
                              _rodando ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 26,
                            ),
                            label: Text(
                              _rodando ? 'Pausar' : 'Iniciar Foco',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _resetarTimer,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF281154),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF9D6BFF).withValues(alpha: 0.55),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFFD8B4FE),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 6. Cartão / Botão sutil para concluir sessão antecipadamente
                      InkWell(
                        onTap: _finalizarSessaoFoco,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF34D399),
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Concluir sessão agora (+25 XP)',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
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
} 