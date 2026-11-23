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
  bool _carregando = true;
  String _filtroCategoria = 'Todas';

  final _categorias = ['Todas', 'Estudo', 'Trabalho', 'Pessoal', 'Saúde'];

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    setState(() => _carregando = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final dados = await _supabase
          .from('tarefas')
          .select()
          .eq('usuario_id', userId)
          .order('concluida', ascending: true)
          .order('criada_em', ascending: false);

      if (mounted) {
        setState(() => _tarefas = dados);
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
        aoSalvar: _carregarTarefas,
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

      await _carregarTarefas();

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
      await _carregarTarefas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Color _corPrioridade(String prioridade) {
    if (prioridade == 'Alta') return const Color(0xFFEF4444);
    if (prioridade == 'Média') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _formatarData(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tarefasFiltradas = _filtroCategoria == 'Todas'
        ? _tarefas
        : _tarefas.where((t) => t['categoria'] == _filtroCategoria).toList();

    final pendentes = tarefasFiltradas.where((t) => t['concluida'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Tarefas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF251742),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Atualizar lista',
            icon: const Icon(Icons.refresh, color: Color(0xFFA78BFA)),
            onPressed: _carregarTarefas,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              pendentes == 0
                  ? 'Tudo em dia por aqui!'
                  : 'Você tem $pendentes ${pendentes == 1 ? 'tarefa pendente' : 'tarefas pendentes'}',
              style: const TextStyle(color: Color(0xFFE2D9F3), fontSize: 15),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categorias.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                final selecionada = _filtroCategoria == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selecionada,
                  onSelected: (_) => setState(() => _filtroCategoria = cat),
                  selectedColor: const Color(0xFF8B5CF6),
                  backgroundColor: const Color(0xFF251742),
                  labelStyle: TextStyle(
                    color: selecionada ? Colors.white : const Color(0xFFE2D9F3),
                    fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : tarefasFiltradas.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 64, color: Color(0xFF4C3575)),
                            SizedBox(height: 12),
                            Text(
                              'Nenhuma tarefa encontrada.',
                              style: TextStyle(color: Color(0xFFE2D9F3), fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Toque no botão + para adicionar uma.',
                              style: TextStyle(color: Color(0xFFA78BFA), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                        itemCount: tarefasFiltradas.length,
                        itemBuilder: (context, index) {
                          final tarefa = tarefasFiltradas[index];
                          final concluida = tarefa['concluida'] as bool;
                          final corPrio = _corPrioridade(tarefa['prioridade'] ?? 'Baixa');
                          final dataTexto = _formatarData(tarefa['prazo']?.toString());

                          return Card(
                            color: const Color(0xFF251742),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: concluida ? Colors.transparent : corPrio.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              onTap: () => _abrirModalTarefa(tarefa),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              leading: Checkbox(
                                value: concluida,
                                activeColor: const Color(0xFF8B5CF6),
                                side: const BorderSide(color: Color(0xFFA78BFA), width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                onChanged: (_) => _alternarConclusao(tarefa),
                              ),
                              title: Text(
                                tarefa['titulo'],
                                style: TextStyle(
                                  color: concluida ? Colors.white54 : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  decoration: concluida ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF160D28),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tarefa['categoria'],
                                        style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(color: corPrio, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tarefa['prioridade'],
                                          style: TextStyle(color: corPrio, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    if (dataTexto.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.event, size: 13, color: Color(0xFFE2D9F3)),
                                          const SizedBox(width: 3),
                                          Text(
                                            dataTexto,
                                            style: const TextStyle(color: Color(0xFFE2D9F3), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    if (tarefa['publica'] == true)
                                      const Icon(Icons.public, size: 14, color: Color(0xFFE2D9F3)),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Excluir tarefa',
                                icon: const Icon(Icons.delete_outline, color: Colors.white54),
                                onPressed: () => _excluirTarefa(tarefa['id']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalTarefa(),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
