import 'dart:async';
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
      appBar: AppBar(
        title: const Text(
          'Modo Foco',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF251742),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Seletor de Tarefa alvo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF251742),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _tarefasPendentes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Foco livre (nenhuma tarefa pendente)',
                            style: TextStyle(color: Color(0xFFE2D9F3)),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<dynamic>(
                            value: _tarefaSelecionada,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF251742),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA78BFA)),
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            items: _tarefasPendentes.map((t) {
                              return DropdownMenuItem<dynamic>(
                                value: t,
                                child: Text(
                                  'Focar em: ${t['titulo']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _rodando
                                ? null
                                : (nova) => setState(() => _tarefaSelecionada = nova),
                          ),
                        ),
                ),
                const SizedBox(height: 36),

                // Círculo do Cronômetro
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progresso,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFF251742),
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _formatarRelogio(_segundosRestantes),
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rodando ? 'Mantenha o foco!' : 'Pronto para começar',
                          style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Botões de duração rápida
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [15, 25, 45].map((min) {
                    final ativo = _minutosEscolhidos == min;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ChoiceChip(
                        label: Text('$min min'),
                        selected: ativo,
                        onSelected: (_) => _definirTempo(min),
                        selectedColor: const Color(0xFF8B5CF6),
                        backgroundColor: const Color(0xFF251742),
                        labelStyle: TextStyle(
                          color: ativo ? Colors.white : const Color(0xFFE2D9F3),
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Controles Iniciar / Pausar e Resetar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _alternarTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rodando ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(_rodando ? Icons.pause : Icons.play_arrow, size: 26),
                      label: Text(
                        _rodando ? 'Pausar' : 'Iniciar Foco',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Reiniciar tempo',
                      onPressed: _resetarTimer,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF251742),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(Icons.refresh, color: Color(0xFFE2D9F3)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botão para concluir sessão antecipadamente e resgatar XP
                TextButton.icon(
                  onPressed: _finalizarSessaoFoco,
                  icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                  label: const Text(
                    'Concluir sessão agora (+25 XP)',
                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
