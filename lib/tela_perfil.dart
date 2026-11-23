import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final _supabase = Supabase.instance.client;

  String _nome = '';
  String _email = '';
  int _xpSemanal = 0;
  int _diasSeguidos = 1;
  int _tarefasConcluidas = 0;
  int _totalTarefas = 0;
  int _minutosFocados = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() => _carregando = true);
    try {
      final user = _supabase.auth.currentUser!;
      final perfil = await _supabase
          .from('perfis')
          .select()
          .eq('id', user.id)
          .single();

      final tarefas = await _supabase
          .from('tarefas')
          .select('concluida, tempo_focado_minutos')
          .eq('usuario_id', user.id);

      int concluidas = 0;
      int minutos = 0;
      for (final t in tarefas) {
        if (t['concluida'] == true) concluidas++;
        minutos += (t['tempo_focado_minutos'] ?? 0) as int;
      }

      if (mounted) {
        setState(() {
          _nome = perfil['nome'] ?? 'Estudante';
          _email = perfil['email'] ?? (user.email ?? '');
          _xpSemanal = (perfil['xp_semanal'] ?? 0) as int;
          _diasSeguidos = (perfil['dias_seguidos'] ?? 1) as int;
          _totalTarefas = tarefas.length;
          _tarefasConcluidas = concluidas;
          _minutosFocados = minutos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar perfil: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _editarNome() async {
    final controller = TextEditingController(text: _nome);
    final novoNome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF251742),
        title: const Text('Editar Nome', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Seu nome de exibição',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF160D28),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFE2D9F3))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (novoNome != null && novoNome.isNotEmpty && novoNome != _nome) {
      try {
        final userId = _supabase.auth.currentUser!.id;
        await _supabase.from('perfis').update({'nome': novoNome}).eq('id', userId);
        setState(() => _nome = novoNome);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar nome: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Future<void> _sair() async {
    await _supabase.auth.signOut();
  }

  Widget _cardMetrica(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF251742),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: cor, size: 26),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(color: Color(0xFFE2D9F3), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _badgeConquista(String titulo, String desc, IconData icone, bool desbloqueada) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF251742),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: desbloqueada ? const Color(0xFF8B5CF6) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: desbloqueada
                ? const Color(0xFF8B5CF6)
                : const Color(0xFF160D28),
            child: Icon(
              icone,
              color: desbloqueada ? Colors.white : Colors.white24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: desbloqueada ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: Color(0xFFE2D9F3), fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            desbloqueada ? Icons.verified : Icons.lock_outline,
            color: desbloqueada ? const Color(0xFF10B981) : Colors.white24,
            size: 20,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nivel = (_xpSemanal ~/ 100) + 1;
    final progressoNivel = (_xpSemanal % 100) / 100.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF251742),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh, color: Color(0xFFA78BFA)),
            onPressed: _carregarEstatisticas,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : RefreshIndicator(
              onRefresh: _carregarEstatisticas,
              color: const Color(0xFF8B5CF6),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Cartão Principal do Usuário
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF251742),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF8B5CF6),
                          child: Text(
                            _nome.isNotEmpty ? _nome[0].toUpperCase() : 'B',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _nome,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Editar nome',
                              icon: const Icon(Icons.edit, size: 18, color: Color(0xFFA78BFA)),
                              onPressed: _editarNome,
                            ),
                          ],
                        ),
                        Text(
                          _email,
                          style: const TextStyle(color: Color(0xFFE2D9F3), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nível $nivel',
                              style: const TextStyle(
                                color: Color(0xFFA78BFA),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_xpSemanal % 100} / 100 XP para o próximo nível',
                              style: const TextStyle(color: Color(0xFFE2D9F3), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressoNivel,
                            minHeight: 8,
                            backgroundColor: const Color(0xFF160D28),
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid de Estatísticas
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _cardMetrica('XP Semanal', '$_xpSemanal XP', Icons.bolt, const Color(0xFFA78BFA)),
                      _cardMetrica('Ofensiva', '$_diasSeguidos dias', Icons.local_fire_department, const Color(0xFFF59E0B)),
                      _cardMetrica('Concluídas', '$_tarefasConcluidas / $_totalTarefas', Icons.check_circle, const Color(0xFF10B981)),
                      _cardMetrica('Tempo Focado', '$_minutosFocados min', Icons.timer, const Color(0xFF38BDF8)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Conquistas
                  const Text(
                    'Conquistas',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _badgeConquista(
                    'Primeiro Passo',
                    'Conclua pelo menos 1 tarefa',
                    Icons.star,
                    _tarefasConcluidas >= 1,
                  ),
                  _badgeConquista(
                    'Mente Focada',
                    'Acumule 25 minutos no Modo Foco',
                    Icons.psychology,
                    _minutosFocados >= 25,
                  ),
                  _badgeConquista(
                    'Produtividade em Alta',
                    'Alcance 100 XP semanais',
                    Icons.emoji_events,
                    _xpSemanal >= 100,
                  ),
                  const SizedBox(height: 20),

                  // Botão Sair
                  OutlinedButton.icon(
                    onPressed: _sair,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da Conta', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
