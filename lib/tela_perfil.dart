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
        backgroundColor: const Color(0xFF281154),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFF9D6BFF).withValues(alpha: 0.5)),
        ),
        title: const Text('Editar Nome', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Seu nome de exibição',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF13072E),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: const Color(0xFF9D6BFF).withValues(alpha: 0.45)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF682BD7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF281154).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cor.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: cor, size: 22),
          ),
          const Spacer(),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
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

  Widget _badgeConquista(String titulo, String desc, IconData icone, bool desbloqueada, Color corDestaque) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF281154).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: desbloqueada
              ? corDestaque.withValues(alpha: 0.75)
              : const Color(0xFF9D6BFF).withValues(alpha: 0.25),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: desbloqueada
                ? corDestaque.withValues(alpha: 0.22)
                : const Color(0xFF13072E),
            child: Icon(
              icone,
              color: desbloqueada ? corDestaque : Colors.white24,
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
            desbloqueada ? Icons.verified_rounded : Icons.lock_outline_rounded,
            color: desbloqueada ? const Color(0xFF34D399) : Colors.white24,
            size: 21,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nivel = (_xpSemanal ~/ 100) + 1;
    final progressoNivel = (_xpSemanal % 100) / 100.0;
    final taxaConclusao = _totalTarefas > 0
        ? ((_tarefasConcluidas / _totalTarefas) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF13072E),
      body: Stack(
        children: [
          // Duas bolas decorativas no mesmo lugar do background
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
            child: _carregando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D6BFF)))
                : RefreshIndicator(
                    onRefresh: _carregarEstatisticas,
                    color: const Color(0xFF9D6BFF),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        // Cabeçalho estilizado no padrão BeProud
                        Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Center(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Meu ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      TextSpan(
                                        text: 'Perfil',
                                        style: TextStyle(color: Color(0xFF9D6BFF)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _carregarEstatisticas,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF281154),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF9D6BFF).withValues(alpha: 0.55),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xFFD8B4FE),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cartão Principal do Usuário
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF281154).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF9D6BFF).withValues(alpha: 0.6),
                              width: 1.3,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9D6BFF), Color(0xFF682BD7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    _nome.isNotEmpty ? _nome[0].toUpperCase() : 'B',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _nome,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar nome',
                                    icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFFD8B4FE)),
                                    onPressed: _editarNome,
                                  ),
                                ],
                              ),
                              Text(
                                _email,
                                style: const TextStyle(color: Color(0xFFD8B4FE), fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF682BD7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Nível $nivel',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
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
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progressoNivel,
                                  minHeight: 9,
                                  backgroundColor: const Color(0xFF13072E),
                                  color: const Color(0xFF9D6BFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Título da seção de Estatísticas (igual à pág. 8)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bar_chart_rounded, color: Color(0xFF9D6BFF), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Suas Estatísticas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'Taxa: $taxaConclusao%',
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Grid de Estatísticas com contornos de cores diferentes
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.28,
                          children: [
                            _cardMetrica(
                              'XP Semanal',
                              '$_xpSemanal XP',
                              Icons.bolt_rounded,
                              const Color(0xFFA78BFA), // Lilás
                            ),
                            _cardMetrica(
                              'Sequência atual',
                              '$_diasSeguidos dias',
                              Icons.local_fire_department_rounded,
                              const Color(0xFFF59E0B), // Laranja / Ouro
                            ),
                            _cardMetrica(
                              'Tarefas concluídas',
                              '$_tarefasConcluidas / $_totalTarefas',
                              Icons.check_circle_rounded,
                              const Color(0xFF10B981), // Verde Esmeralda
                            ),
                            _cardMetrica(
                              'Tempo focado',
                              '$_minutosFocados min',
                              Icons.timer_rounded,
                              const Color(0xFF38BDF8), // Azul Celeste
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Banner motivacional da página 8 do Figma
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF7C3AED).withValues(alpha: 0.75),
                                const Color(0xFF682BD7).withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD8B4FE).withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.emoji_events_rounded, color: Color(0xFFFACC15), size: 32),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Você está indo muito bem!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Continue assim para alcançar novas conquistas',
                                      style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.trending_up_rounded, color: Color(0xFFE9D5FF), size: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Conquistas com cores distintas
                        const Text(
                          'Conquistas',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _badgeConquista(
                          'Primeiro Passo',
                          'Conclua pelo menos 1 tarefa',
                          Icons.star_rounded,
                          _tarefasConcluidas >= 1,
                          const Color(0xFF10B981),
                        ),
                        _badgeConquista(
                          'Mente Focada',
                          'Acumule 25 minutos no Modo Foco',
                          Icons.psychology_rounded,
                          _minutosFocados >= 25,
                          const Color(0xFF38BDF8),
                        ),
                        _badgeConquista(
                          'Produtividade em Alta',
                          'Alcance 100 XP semanais',
                          Icons.emoji_events_rounded,
                          _xpSemanal >= 100,
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 20),

                        // Botão Sair
                        OutlinedButton.icon(
                          onPressed: _sair,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                            side: const BorderSide(color: Colors.redAccent, width: 1.3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sair da Conta', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}