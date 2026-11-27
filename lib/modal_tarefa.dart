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

  final _categorias = ['Estudo', 'Trabalho', 'Pessoal', 'Saúde', 'Lazer'];
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
              surface: Color(0xFF281154),
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

  IconData _iconeCategoria(String cat) {
    switch (cat) {
      case 'Trabalho':
        return Icons.work_outline_rounded;
      case 'Saúde':
        return Icons.favorite_border_rounded;
      case 'Pessoal':
        return Icons.star_border_rounded;
      case 'Lazer':
        return Icons.sports_esports_outlined;
      case 'Estudo':
      default:
        return Icons.school_outlined;
    }
  }

  Widget _blocoSecao({
    required IconData icone,
    required String titulo,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF281154).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF9D6BFF).withValues(alpha: 0.45),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: const Color(0xFF9D6BFF), size: 19),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xFF13072E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF9D6BFF).withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D6BFF).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Cabeçalho no estilo da página 6 do Figma
            Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: _modoEdicao ? 'Editar ' : 'Criar Nova ',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const TextSpan(
                              text: 'Tarefa',
                              style: TextStyle(color: Color(0xFF9D6BFF)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Organize a sua rotina e alcance seus objetivos!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFD8B4FE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF281154),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9D6BFF).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFD8B4FE),
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Nome da tarefa
            _blocoSecao(
              icone: Icons.edit_outlined,
              titulo: 'Nome da tarefa',
              child: TextField(
                controller: _tituloController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Ex: Estudar IHC para a prova',
                  hintStyle: const TextStyle(color: Color(0xFFB794F4), fontSize: 13.5),
                  filled: true,
                  fillColor: const Color(0xFF13072E).withValues(alpha: 0.7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Colors.white, width: 1.4),
                  ),
                ),
              ),
            ),

            // 2. Categoria em pílulas com ícones
            _blocoSecao(
              icone: Icons.grid_view_rounded,
              titulo: 'Categoria',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categorias.map((cat) {
                  final selecionada = _categoria == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _categoria = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selecionada
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF13072E).withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selecionada
                              ? const Color(0xFFE9D5FF)
                              : const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconeCategoria(cat),
                            size: 16,
                            color: selecionada ? Colors.white : const Color(0xFF9D6BFF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              color: selecionada ? Colors.white : const Color(0xFFE2D9F3),
                              fontWeight: selecionada ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 3. Prioridade em pílulas com indicador circular e cor
            _blocoSecao(
              icone: Icons.local_fire_department_rounded,
              titulo: 'Prioridade',
              child: Row(
                children: _prioridades.map((prio) {
                  final selecionada = _prioridade == prio;
                  final cor = _corPrioridade(prio);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _prioridade = prio),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selecionada
                              ? cor.withValues(alpha: 0.25)
                              : const Color(0xFF13072E).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selecionada
                                ? cor
                                : const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                            width: selecionada ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selecionada
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 15,
                              color: selecionada ? cor : const Color(0xFF9D6BFF),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              prio,
                              style: TextStyle(
                                color: selecionada ? Colors.white : const Color(0xFFE2D9F3),
                                fontWeight: selecionada ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 4. Prazo (opcional)
            _blocoSecao(
              icone: Icons.calendar_today_rounded,
              titulo: 'Prazo (opcional)',
              child: InkWell(
                onTap: _selecionarPrazo,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13072E).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded, color: Color(0xFF9D6BFF), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _prazo == null
                              ? 'Selecionar data'
                              : 'Prazo: ${_prazo!.day.toString().padLeft(2, '0')}/${_prazo!.month.toString().padLeft(2, '0')}/${_prazo!.year}',
                          style: TextStyle(
                            color: _prazo == null ? const Color(0xFFB794F4) : Colors.white,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (_prazo != null)
                        GestureDetector(
                          onTap: () => setState(() => _prazo = null),
                          child: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Visibilidade (Público / Privado como na pág. 6)
            _blocoSecao(
              icone: Icons.lock_outline_rounded,
              titulo: 'Visibilidade (Feed dos amigos)',
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _publica = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _publica
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF13072E).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _publica
                                ? const Color(0xFFE9D5FF)
                                : const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              size: 18,
                              color: _publica ? Colors.white : const Color(0xFF9D6BFF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Público',
                              style: TextStyle(
                                color: _publica ? Colors.white : const Color(0xFFE2D9F3),
                                fontWeight: _publica ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _publica = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_publica
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF13072E).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: !_publica
                                ? const Color(0xFFE9D5FF)
                                : const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 17,
                              color: !_publica ? Colors.white : const Color(0xFF9D6BFF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Privado',
                              style: TextStyle(
                                color: !_publica ? Colors.white : const Color(0xFFE2D9F3),
                                fontWeight: !_publica ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Botão principal "+ Criar tarefa" em pílula grande
            ElevatedButton.icon(
              onPressed: _salvando ? null : _salvarTarefa,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: _salvando
                  ? const SizedBox.shrink()
                  : Icon(
                      _modoEdicao ? Icons.check_rounded : Icons.add_rounded,
                      size: 24,
                    ),
              label: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _modoEdicao ? 'Salvar Alterações' : 'Criar tarefa',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 10),

            // Botão "Cancelar" em pílula com contorno (igual à pág. 6)
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF682BD7).withValues(alpha: 0.35),
                side: BorderSide(
                  color: const Color(0xFF9D6BFF).withValues(alpha: 0.6),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}