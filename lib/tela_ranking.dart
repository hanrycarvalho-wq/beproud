import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaRanking extends StatefulWidget {
  const TelaRanking({super.key});

  @override
  State<TelaRanking> createState() => _TelaRankingState();
}

class _TelaRankingState extends State<TelaRanking> {
  final _supabase = Supabase.instance.client;
  final _buscaController = TextEditingController();

  var _ranking = [];
  var _convitesRecebidos = [];
  bool _carregando = true;
  bool _enviandoConvite = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1. Busca todas as amizades em que o usuário participa
      final amizades = await _supabase
          .from('amizades')
          .select()
          .or('solicitante_id.eq.$userId,destinatario_id.eq.$userId');

      final idsAmigosAceitos = <String>{userId};
      final idsSolicitantesPendentes = <String>[];
      final mapaConvitePorSolicitante = <String, dynamic>{};

      for (final a in amizades) {
        final status = a['status'];
        final sol = a['solicitante_id'].toString();
        final dest = a['destinatario_id'].toString();

        if (status == 'aceito') {
          idsAmigosAceitos.add(sol == userId ? dest : sol);
        } else if (status == 'pendente' && dest == userId) {
          idsSolicitantesPendentes.add(sol);
          mapaConvitePorSolicitante[sol] = a;
        }
      }

      // 2. Busca perfis dos amigos aceitos + o próprio usuário ordenados por XP
      final listaPerfis = await _supabase
          .from('perfis')
          .select()
          .inFilter('id', idsAmigosAceitos.toList())
          .order('xp_semanal', ascending: false);

      // 3. Busca perfis de quem enviou convite pendente
      var listaConvites = [];
      if (idsSolicitantesPendentes.isNotEmpty) {
        final perfisPendentes = await _supabase
            .from('perfis')
            .select()
            .inFilter('id', idsSolicitantesPendentes);

        listaConvites = perfisPendentes.map((p) {
          final convite = mapaConvitePorSolicitante[p['id'].toString()];
          return {
            'amizade_id': convite['id'],
            'nome': p['nome'],
            'email': p['email'],
          };
        }).toList();
      }

      if (mounted) {
        setState(() {
          _ranking = listaPerfis;
          _convitesRecebidos = listaConvites;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar ranking: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviarConvite() async {
    final emailBusca = _buscaController.text.trim().toLowerCase();
    if (emailBusca.isEmpty) return;

    setState(() => _enviandoConvite = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final meuEmail = _supabase.auth.currentUser!.email?.toLowerCase();

      if (emailBusca == meuEmail) {
        throw 'Você não pode adicionar a si mesmo.';
      }

      final alvo = await _supabase
          .from('perfis')
          .select()
          .ilike('email', emailBusca)
          .maybeSingle();

      if (alvo == null) {
        throw 'Nenhum usuário encontrado com esse e-mail.';
      }

      final amigoId = alvo['id'].toString();

      final existente = await _supabase
          .from('amizades')
          .select()
          .or('and(solicitante_id.eq.$userId,destinatario_id.eq.$amigoId),and(solicitante_id.eq.$amigoId,destinatario_id.eq.$userId)')
          .maybeSingle();

      if (existente != null) {
        throw existente['status'] == 'aceito'
            ? 'Vocês já são amigos!'
            : 'Já existe uma solicitação pendente entre vocês.';
      }

      await _supabase.from('amizades').insert({
        'solicitante_id': userId,
        'destinatario_id': amigoId,
        'status': 'pendente',
      });

      _buscaController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitação enviada para ${alvo['nome']}!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.orangeAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoConvite = false);
    }
  }

  Future<void> _responderConvite(int amizadeId, bool aceitar) async {
    try {
      if (aceitar) {
        await _supabase.from('amizades').update({'status': 'aceito'}).eq('id', amizadeId);
      } else {
        await _supabase.from('amizades').delete().eq('id', amizadeId);
      }
      await _carregarDados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao responder convite: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _badgePosicao(int index) {
    if (index == 0) {
      return const CircleAvatar(
        backgroundColor: Color(0xFFF59E0B),
        child: Icon(Icons.emoji_events, color: Colors.white, size: 20),
      );
    }
    if (index == 1) {
      return const CircleAvatar(
        backgroundColor: Color(0xFF94A3B8),
        child: Text('2º', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    if (index == 2) {
      return const CircleAvatar(
        backgroundColor: Color(0xFFB45309),
        child: Text('3º', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFF160D28),
      child: Text(
        '${index + 1}º',
        style: const TextStyle(color: Color(0xFFE2D9F3), fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ranking & Amigos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF251742),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Atualizar placar',
            icon: const Icon(Icons.refresh, color: Color(0xFFA78BFA)),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : RefreshIndicator(
              onRefresh: _carregarDados,
              color: const Color(0xFF8B5CF6),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Barra de adicionar amigo por e-mail
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _buscaController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Adicionar amigo por e-mail...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                            prefixIcon: const Icon(Icons.person_add_alt_1, color: Color(0xFFA78BFA)),
                            filled: true,
                            fillColor: const Color(0xFF251742),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _enviandoConvite ? null : _enviarConvite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _enviandoConvite
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Enviar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Convites pendentes recebidos
                  if (_convitesRecebidos.isNotEmpty) ...[
                    const Text(
                      'Solicitações Pendentes',
                      style: TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    ..._convitesRecebidos.map((convite) {
                      return Card(
                        color: const Color(0xFF251742),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          title: Text(
                            convite['nome'] ?? 'Usuário',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            convite['email'] ?? '',
                            style: const TextStyle(color: Color(0xFFE2D9F3), fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Aceitar',
                                icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                                onPressed: () => _responderConvite(convite['amizade_id'], true),
                              ),
                              IconButton(
                                tooltip: 'Recusar',
                                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                onPressed: () => _responderConvite(convite['amizade_id'], false),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Cabeçalho do Placar
                  const Text(
                    'Placar Semanal',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Conclua tarefas e sessões de foco para subir no ranking',
                    style: TextStyle(color: Color(0xFFE2D9F3), fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // Lista do Ranking
                  ...List.generate(_ranking.length, (index) {
                    final pessoa = _ranking[index];
                    final souEu = pessoa['id'].toString() == userId;
                    final xp = pessoa['xp_semanal'] ?? 0;
                    final dias = pessoa['dias_seguidos'] ?? 1;

                    return Card(
                      color: souEu ? const Color(0xFF331F5C) : const Color(0xFF251742),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: souEu ? const Color(0xFF8B5CF6) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: _badgePosicao(index),
                        title: Text(
                          souEu ? '${pessoa['nome']} (Você)' : pessoa['nome'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.local_fire_department, size: 15, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              '$dias ${dias == 1 ? 'dia seguido' : 'dias seguidos'}',
                              style: const TextStyle(color: Color(0xFFE2D9F3), fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF160D28),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$xp XP',
                            style: const TextStyle(
                              color: Color(0xFFA78BFA),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
