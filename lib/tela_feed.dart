import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaFeed extends StatefulWidget {
  const TelaFeed({super.key});

  @override
  State<TelaFeed> createState() => _TelaFeedState();
}

class _TelaFeedState extends State<TelaFeed> {
  final _supabase = Supabase.instance.client;
  var _atividades = [];
  final _aplaudidos = <int>{};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarFeed();
  }

  Future<void> _carregarFeed() async {
    setState(() => _carregando = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1. Busca IDs dos amigos aceitos + o próprio usuário
      final amizades = await _supabase
          .from('amizades')
          .select()
          .eq('status', 'aceito')
          .or('solicitante_id.eq.$userId,destinatario_id.eq.$userId');

      final idsVisiveis = <String>{userId};
      for (final a in amizades) {
        final sol = a['solicitante_id'].toString();
        final dest = a['destinatario_id'].toString();
        idsVisiveis.add(sol == userId ? dest : sol);
      }

      // 2. Busca os nomes dos perfis visíveis
      final perfis = await _supabase
          .from('perfis')
          .select('id, nome')
          .inFilter('id', idsVisiveis.toList());

      final mapaNomes = <String, String>{};
      for (final p in perfis) {
        mapaNomes[p['id'].toString()] = p['nome'] ?? 'Usuário';
      }

      // 3. Busca tarefas marcadas como públicas desses usuários
      final tarefasPublicas = await _supabase
          .from('tarefas')
          .select()
          .eq('publica', true)
          .inFilter('usuario_id', idsVisiveis.toList())
          .order('criada_em', ascending: false)
          .limit(30);

      final listaMontada = tarefasPublicas.map((t) {
        final autorId = t['usuario_id'].toString();
        return {
          ...t,
          'autor_nome': autorId == userId
              ? '${mapaNomes[autorId] ?? 'Você'} (Você)'
              : (mapaNomes[autorId] ?? 'Amigo'),
          'sou_eu': autorId == userId,
        };
      }).toList();

      if (mounted) {
        setState(() => _atividades = listaMontada);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar feed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _tempoRelativo(String? iso) {
    if (iso == null) return 'Agora';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return 'Agora';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours} h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13072E), // Mesmo fundo das outras telas
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
            child: Column(
              children: [
                // Cabeçalho padronizado no estilo BeProud
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
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
                                  text: 'Feed da ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Comunidade',
                                  style: TextStyle(color: Color(0xFF9D6BFF)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _carregarFeed,
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
                ),
                const Text(
                  'Acompanhe e apoie as conquistas dos seus amigos',
                  style: TextStyle(color: Color(0xFFD8B4FE), fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Conteúdo do Feed
                Expanded(
                  child: _carregando
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D6BFF)))
                      : _atividades.isEmpty
                          ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F0D42).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.public_rounded, size: 56, color: Color(0xFF9D6BFF)),
                                    SizedBox(height: 12),
                                    Text(
                                      'Nenhuma atividade pública ainda.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Ative a opção "Tarefa pública" ao criar uma tarefa para compartilhar suas metas aqui.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Color(0xFFD8B4FE), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _carregarFeed,
                              color: const Color(0xFF9D6BFF),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                                itemCount: _atividades.length,
                                itemBuilder: (context, index) {
                                  final item = _atividades[index];
                                  final id = item['id'] as int;
                                  final concluida = item['concluida'] == true;
                                  final minutosFocados = (item['tempo_focado_minutos'] ?? 0) as int;
                                  final aplaudiu = _aplaudidos.contains(id);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF281154).withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: concluida
                                            ? const Color(0xFF10B981).withValues(alpha: 0.55)
                                            : const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Cabeçalho com Avatar, Nome e Status
                                        Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF682BD7),
                                                border: Border.all(
                                                  color: const Color(0xFF9D6BFF),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (item['autor_nome'] as String)[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['autor_nome'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14.5,
                                                    ),
                                                  ),
                                                  Text(
                                                    _tempoRelativo(item['criada_em']?.toString()),
                                                    style: const TextStyle(
                                                      color: Color(0xFFD8B4FE),
                                                      fontSize: 11.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 11,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: concluida
                                                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                                    : const Color(0xFF682BD7).withValues(alpha: 0.45),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: concluida
                                                      ? const Color(0xFF34D399).withValues(alpha: 0.5)
                                                      : const Color(0xFF9D6BFF).withValues(alpha: 0.5),
                                                ),
                                              ),
                                              child: Text(
                                                concluida ? 'Concluída' : 'Em andamento',
                                                style: TextStyle(
                                                  color: concluida
                                                      ? const Color(0xFF34D399)
                                                      : const Color(0xFFE9D5FF),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Título da tarefa compartilhada
                                        Text(
                                          item['titulo'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Tags e Botão de Apoio em pílula
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF13072E),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(0xFF9D6BFF).withValues(alpha: 0.35),
                                                ),
                                              ),
                                              child: Text(
                                                item['categoria'] ?? 'Geral',
                                                style: const TextStyle(
                                                  color: Color(0xFFD8B4FE),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            if (minutosFocados > 0) ...[
                                              const SizedBox(width: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.timer_outlined,
                                                    size: 14,
                                                    color: Color(0xFFFACC15),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$minutosFocados min',
                                                    style: const TextStyle(
                                                      color: Color(0xFFE2D9F3),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (aplaudiu) {
                                                    _aplaudidos.remove(id);
                                                  } else {
                                                    _aplaudidos.add(id);
                                                  }
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: aplaudiu
                                                      ? const Color(0xFF7C3AED)
                                                      : const Color(0xFF13072E),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: aplaudiu
                                                        ? const Color(0xFFD8B4FE)
                                                        : const Color(0xFF9D6BFF).withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      aplaudiu
                                                          ? Icons.favorite_rounded
                                                          : Icons.favorite_border_rounded,
                                                      size: 15,
                                                      color: aplaudiu
                                                          ? Colors.white
                                                          : const Color(0xFF9D6BFF),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      aplaudiu ? 'Apoiado!' : 'Apoiar',
                                                      style: TextStyle(
                                                        color: aplaudiu
                                                            ? Colors.white
                                                            : const Color(0xFFE2D9F3),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}