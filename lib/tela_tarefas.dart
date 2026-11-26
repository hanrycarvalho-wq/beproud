import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'modal_tarefa.dart';

class TelaTarefas extends StatefulWidget {
  const TelaTarefas({super.key});

  @override
  State<TelaTarefas> createState() => _TelaTarefasState();
}

class _TelaTarefasState extends State<TelaTarefas> {
  final _supabase = Supabase.instance.client;
  var _tarefas = [];
  String _nomeUsuario = 'Usuário';
  bool _carregando = true;
  String _filtroCategoria = 'Todas';

  final _categorias = ['Todas', 'Estudo', 'Trabalho', 'Pessoal', 'Saúde', 'Lazer'];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Busca o nome do usuário para a saudação "Olá, [Nome]!"
      final perfil = await _supabase
          .from('perfis')
          .select('nome')
          .eq('id', userId)
          .maybeSingle();

      // Busca as tarefas do usuário
      final dados = await _supabase
          .from('tarefas')
          .select()
          .eq('usuario_id', userId)
          .order('concluida', ascending: true)
          .order('criada_em', ascending: false);

      if (mounted) {
        setState(() {
          if (perfil != null && perfil['nome'] != null) {
            _nomeUsuario = perfil['nome'].toString().split(' ').first;
          }
          _tarefas = dados;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirModalTarefa([dynamic tarefa]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModalTarefa(
        tarefaExistente: tarefa,
        aoSalvar: _carregarDados,
      ),
    );
  }

  Future<void> _alternarConclusao(dynamic tarefa) async {
    final novoStatus = !(tarefa['concluida'] as bool);
    final userId = _supabase.auth.currentUser!.id;

    try {
      await _supabase
          .from('tarefas')
          .update({'concluida': novoStatus})
          .eq('id', tarefa['id']);

      final perfil = await _supabase
          .from('perfis')
          .select('xp_semanal')
          .eq('id', userId)
          .single();

      final xpAtual = (perfil['xp_semanal'] ?? 0) as int;
      final novoXp = novoStatus ? xpAtual + 15 : (xpAtual - 15).clamp(0, 999999);

      await _supabase
          .from('perfis')
          .update({'xp_semanal': novoXp})
          .eq('id', userId);

      await _carregarDados();

      if (mounted && novoStatus) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa concluída! +15 XP'),
            backgroundColor: Color(0xFF8B5CF6),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _excluirTarefa(int id) async {
    try {
      await _supabase.from('tarefas').delete().eq('id', id);
      await _carregarDados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Cores das etiquetas de categoria iguais às da página 5 do Figma
  Color _corCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'estudo':
        return const Color(0xFFBE185D); // Rosa/Vinho
      case 'saúde':
        return const Color.fromARGB(255, 25, 171, 61); // Roxo
      case 'pessoal':
        return const Color.fromARGB(255, 42, 23, 211); // Verde água
      case 'trabalho':
        return const Color(0xFFD97706); // Âmbar
      case 'lazer':
      default:
        return const Color(0xFF4C1D95); // Roxo escuro
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarefasFiltradas = _filtroCategoria == 'Todas'
        ? _tarefas
        : _tarefas.where((t) => t['categoria'] == _filtroCategoria).toList();

    final totalTarefas = _tarefas.length;
    final concluidas = _tarefas.where((t) => t['concluida'] == true).length;
    final double progresso = totalTarefas == 0 ? 0.0 : concluidas / totalTarefas;
    final int porcentagem = (progresso * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF13072E), // Fundo roxo bem escuro do Figma
      body: Stack(
        children: [
          // Formas circulares decorativas de fundo
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
                    onRefresh: _carregarDados,
                    color: const Color(0xFF9D6BFF),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                            children: [
                              // 1. Cabeçalho: Ícone + Logo BeProud + Avatar de Perfil
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(width: 42), // Equilibra o centro
                                  Row(
                                    children: [
                                      Transform.rotate(
                                        angle: -12 * math.pi / 180,
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C3AED),
                                            borderRadius: BorderRadius.circular(9),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFF13072E),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
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
                                  Stack(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF9D6BFF),
                                            width: 2.5,
                                          ),
                                          color: const Color(0xFF25124D),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF9D6BFF),
                                          size: 26,
                                        ),
                                      ),
                                      Positioned(
                                        right: 1,
                                        bottom: 1,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF22C55E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // 2. Saudação: "Olá, Hanry!"
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Olá, ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      TextSpan(
                                        text: '$_nomeUsuario!',
                                        style: const TextStyle(color: Color(0xFF9D6BFF)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 3. Cartão de Progresso (67% + Barra horizontal)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF281154).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                                    width: 1,
                                  ),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 68,
                                        height: 68,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 68,
                                              height: 68,
                                              child: CircularProgressIndicator(
                                                value: progresso,
                                                strokeWidth: 7,
                                                backgroundColor: const Color(0xFF3E1E7A),
                                                valueColor: const AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF8B5CF6),
                                                ),
                                                strokeCap: StrokeCap.round,
                                              ),
                                            ),
                                            Text(
                                              '$porcentagem%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const VerticalDivider(
                                        color: Color(0xFF7C3AED),
                                        thickness: 1,
                                        width: 28,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$concluidas de $totalTarefas tarefas concluídas hoje',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: LinearProgressIndicator(
                                                value: progresso,
                                                minHeight: 10,
                                                backgroundColor: const Color(0xFF682BD7),
                                                valueColor: const AlwaysStoppedAnimation<Color>(
                                                  Color(0xFFD8B4FE),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 4. Linha "Suas tarefas" + Botão de filtro arredondado à direita
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Color(0xFF9D6BFF),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Suas tarefas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF281154),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF9D6BFF).withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _filtroCategoria,
                                        isDense: true,
                                        dropdownColor: const Color(0xFF281154),
                                        icon: const Icon(
                                          Icons.arrow_downward_rounded,
                                          color: Color(0xFF9D6BFF),
                                          size: 16,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                        items: _categorias
                                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _filtroCategoria = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // 5. Lista de Tarefas estilo pílula do Figma
                              if (tarefasFiltradas.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: Text(
                                      'Nenhuma tarefa por aqui.\nToque no + abaixo para criar!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Color(0xFFD8B4FE), fontSize: 15),
                                    ),
                                  ),
                                )
                              else
                                ...tarefasFiltradas.map((tarefa) {
                                  final concluida = tarefa['concluida'] == true;
                                  final categoria = (tarefa['categoria'] ?? 'Geral').toString();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F0D42).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFF9D6BFF).withValues(alpha: 0.55),
                                        width: 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _abrirModalTarefa(tarefa),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            // Checkbox roxo arredondado
                                            GestureDetector(
                                              onTap: () => _alternarConclusao(tarefa),
                                              child: Container(
                                                width: 26,
                                                height: 26,
                                                decoration: BoxDecoration(
                                                  color: concluida
                                                      ? const Color(0xFF7C3AED)
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(7),
                                                  border: Border.all(
                                                    color: const Color(0xFF7C3AED),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: concluida
                                                    ? const Icon(
                                                        Icons.check_rounded,
                                                        size: 18,
                                                        color: Color(0xFF13072E),
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Título da tarefa
                                            Expanded(
                                              child: Text(
                                                tarefa['titulo'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: concluida
                                                      ? const Color(0xFF9D6BFF).withValues(alpha: 0.65)
                                                      : Colors.white,
                                                  fontSize: 15.5,
                                                  decoration: concluida
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  decorationColor: const Color(0xFF9D6BFF),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Etiqueta de categoria (Estudos, Lazer, Saúde...)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _corCategoria(categoria),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                categoria,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),

                                            // Menu de opções (...) para editar ou excluir
                                            PopupMenuButton<String>(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.more_horiz,
                                                color: Colors.white70,
                                                size: 20,
                                              ),
                                              color: const Color(0xFF281154),
                                              onSelected: (opcao) {
                                                if (opcao == 'editar') {
                                                  _abrirModalTarefa(tarefa);
                                                } else if (opcao == 'excluir') {
                                                  _excluirTarefa(tarefa['id']);
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'editar',
                                                  child: Text(
                                                    'Editar',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'excluir',
                                                  child: Text(
                                                    'Excluir',
                                                    style: TextStyle(color: Colors.redAccent),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),

                        // 6. Rodapé fixo: Banner do Troféu + Botão circular (+)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF682BD7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.emoji_events_rounded,
                                        color: Color(0xFFFACC15),
                                        size: 32,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Sua produtividade hoje está incrível!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              porcentagem >= 50
                                                  ? 'Você está no top 20% dos usuários.'
                                                  : 'Conclua tarefas para subir no ranking!',
                                              style: const TextStyle(
                                                color: Color(0xFFE9D5FF),
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _abrirModalTarefa(),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF682BD7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFF13072E),
                                    size: 34,
                                  ),
                                ),
                              ),
                            ],
                          ),
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