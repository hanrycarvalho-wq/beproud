import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModalTarefa extends StatefulWidget {
  final dynamic tarefaExistente;
  final VoidCallback aoSalvar;

  const ModalTarefa({
    super.key,
    this.tarefaExistente,
    required this.aoSalvar,
  });

  @override
  State<ModalTarefa> createState() => _ModalTarefaState();
}

class _ModalTarefaState extends State<ModalTarefa> {
  final _supabase = Supabase.instance.client;
  final _tituloController = TextEditingController();

  String _categoria = 'Estudo';
  String _prioridade = 'Média';
  DateTime? _prazo;
  bool _publica = false;
  bool _salvando = false;

  final _categorias = ['Estudo', 'Trabalho', 'Pessoal', 'Saúde'];
  final _prioridades = ['Baixa', 'Média', 'Alta'];

  bool get _modoEdicao => widget.tarefaExistente != null;

  @override
  void initState() {
    super.initState();
    if (_modoEdicao) {
      final t = widget.tarefaExistente;
      _tituloController.text = t['titulo'] ?? '';
      _categoria = _categorias.contains(t['categoria']) ? t['categoria'] : 'Estudo';
      _prioridade = _prioridades.contains(t['prioridade']) ? t['prioridade'] : 'Média';
      _publica = t['publica'] == true;
      if (t['prazo'] != null) {
        _prazo = DateTime.tryParse(t['prazo'].toString());
      }
    }
  }

  Future<void> _selecionarPrazo() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _prazo ?? agora,
      firstDate: DateTime(agora.year - 1),
      lastDate: DateTime(agora.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5CF6),
              onPrimary: Colors.white,
              surface: Color(0xFF251742),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (escolhida != null) {
      setState(() => _prazo = escolhida);
    }
  }

  Future<void> _salvarTarefa() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dê um título para a sua tarefa.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final dados = {
        'usuario_id': userId,
        'titulo': titulo,
        'categoria': _categoria,
        'prioridade': _prioridade,
        'prazo': _prazo?.toIso8601String(),
        'publica': _publica,
      };

      if (_modoEdicao) {
        await _supabase
            .from('tarefas')
            .update(dados)
            .eq('id', widget.tarefaExistente['id']);
      } else {
        await _supabase.from('tarefas').insert(dados);
      }

      widget.aoSalvar();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar tarefa: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Color _corPrioridade(String p) {
    if (p == 'Alta') return const Color(0xFFEF4444);
    if (p == 'Média') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1236),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C3575),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _modoEdicao ? 'Editar Tarefa' : 'Nova Tarefa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFE2D9F3)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tituloController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'O que você precisa fazer?',
                labelStyle: const TextStyle(color: Color(0xFFE2D9F3)),
                hintText: 'Ex: Estudar IHC para a prova',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF251742),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Categoria',
              style: TextStyle(color: Color(0xFFE2D9F3), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categorias.map((cat) {
                final selecionada = _categoria == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selecionada,
                  onSelected: (_) => setState(() => _categoria = cat),
                  selectedColor: const Color(0xFF8B5CF6),
                  backgroundColor: const Color(0xFF251742),
                  labelStyle: TextStyle(
                    color: selecionada ? Colors.white : const Color(0xFFE2D9F3),
                    fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Prioridade',
              style: TextStyle(color: Color(0xFFE2D9F3), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: _prioridades.map((prio) {
                final selecionada = _prioridade == prio;
                final cor = _corPrioridade(prio);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(prio, textAlign: TextAlign.center),
                      ),
                      selected: selecionada,
                      onSelected: (_) => setState(() => _prioridade = prio),
                      selectedColor: cor.withValues(alpha: 0.25),
                      backgroundColor: const Color(0xFF251742),
                      labelStyle: TextStyle(
                        color: selecionada ? cor : const Color(0xFFE2D9F3),
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide(
                        color: selecionada ? cor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _selecionarPrazo,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF251742),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFFA78BFA), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _prazo == null
                            ? 'Definir prazo (opcional)'
                            : 'Prazo: ${_prazo!.day.toString().padLeft(2, '0')}/${_prazo!.month.toString().padLeft(2, '0')}/${_prazo!.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (_prazo != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () => setState(() => _prazo = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF251742),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                value: _publica,
                onChanged: (val) => setState(() => _publica = val),
                activeThumbColor: const Color(0xFF8B5CF6),
                title: const Text(
                  'Tarefa pública',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Compartilhar conquista no Feed dos amigos',
                  style: TextStyle(color: Color(0xFFE2D9F3), fontSize: 12),
                ),
                secondary: const Icon(Icons.public, color: Color(0xFFA78BFA)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvando ? null : _salvarTarefa,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _modoEdicao ? 'Salvar Alterações' : 'Criar Tarefa',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
