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

  Widget _construirDegrauPodio(dynamic pessoa, int posicao, double alturaDegrau, double tamanhoAvatar, String userId) {
    final souEu = pessoa['id'].toString() == userId;
    final xp = pessoa['xp_semanal'] ?? 0;
    final nome = (pessoa['nome'] ?? 'Usuário').toString();
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : 'U';
    final primeiroLugar = posicao == 1;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: tamanhoAvatar,
                height: tamanhoAvatar,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primeiroLugar ? const Color(0xFF7C3AED) : const Color(0xFF3B1A78),
                  border: Border.all(
                    color: primeiroLugar ? const Color(0xFFFACC15) : const Color(0xFF9D6BFF),
                    width: primeiroLugar ? 2.5 : 1.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    inicial,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: primeiroLugar ? 26 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -12,
                right: -4,
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: posicao == 1
                      ? const Color(0xFFFACC15)
                      : posicao == 2
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFF59E0B),
                  size: primeiroLugar ? 24 : 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: alturaDegrau,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: primeiroLugar ? const Color(0xFF682BD7) : const Color(0xFF3B1A78),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(10),
              ),
              border: Border.all(
                color: const Color(0xFF9D6BFF).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$posicao',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: primeiroLugar ? 22 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  souEu ? '$nome (Você)' : nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE9D5FF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$xp XP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser!.id;
    final restante = _ranking.length > 3 ? _ranking.sublist(3) : [];
    final minhaPosicao = _ranking.indexWhere((p) => p['id'].toString() == userId) + 1;

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
                    onRefresh: _carregarDados,
                    color: const Color(0xFF9D6BFF),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        // Título Ranking & Amigos + botão de atualizar
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
                                        text: 'Ranking & ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      TextSpan(
                                        text: 'Amigos',
                                        style: TextStyle(color: Color(0xFF9D6BFF)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Atualizar placar',
                              icon: const Icon(Icons.refresh, color: Color(0xFFA78BFA)),
                              onPressed: _carregarDados,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

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
                                  fillColor: const Color(0xFF281154).withValues(alpha: 0.9),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF9D6BFF).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _enviandoConvite ? null : _enviarConvite,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF682BD7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Color(0xFF9D6BFF)),
                                ),
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
                        const SizedBox(height: 18),

                        // Convites pendentes recebidos
                        if (_convitesRecebidos.isNotEmpty) ...[
                          const Text(
                            'Solicitações Pendentes',
                            style: TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          ..._convitesRecebidos.map((convite) {
                            return Card(
                              color: const Color(0xFF281154),
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: const Color(0xFF9D6BFF).withValues(alpha: 0.45)),
                              ),
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
                          const SizedBox(height: 14),
                        ],

                        // Pódio dos 3 primeiros colocados
                        if (_ranking.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (_ranking.length > 1)
                                _construirDegrauPodio(_ranking[1], 2, 110, 56, userId)
                              else
                                const Spacer(),
                              _construirDegrauPodio(_ranking[0], 1, 142, 70, userId),
                              if (_ranking.length > 2)
                                _construirDegrauPodio(_ranking[2], 3, 94, 52, userId)
                              else
                                const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 22),
                        ],

                        // Espaço / Caixa embaixo para o restante dos amigos (4º lugar em diante)
                        const Row(
                          children: [
                            Icon(Icons.groups_rounded, color: Color(0xFF9D6BFF), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Seus Amigos',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F0D42).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF9D6BFF).withValues(alpha: 0.55),
                              width: 1.2,
                            ),
                          ),
                          child: restante.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  child: Text(
                                    'Adicione mais amigos por e-mail acima para preencher a lista abaixo do pódio!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFFE2D9F3), fontSize: 13),
                                  ),
                                )
                              : Column(
                                  children: List.generate(restante.length, (i) {
                                    final pessoa = restante[i];
                                    final posicaoReal = i + 4;
                                    final souEu = pessoa['id'].toString() == userId;
                                    final xp = pessoa['xp_semanal'] ?? 0;
                                    final nome = (pessoa['nome'] ?? 'Usuário').toString();
                                    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : 'U';

                                    return Container(
                                      margin: EdgeInsets.only(bottom: i == restante.length - 1 ? 0 : 10),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: souEu ? const Color(0xFF3B1A78) : const Color(0xFF281154),
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(
                                          color: souEu
                                              ? const Color(0xFFD8B4FE)
                                              : const Color(0xFF9D6BFF).withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            child: Text(
                                              '$posicaoReal',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: const Color(0xFF682BD7),
                                            child: Text(
                                              inicial,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              souEu ? '$nome (Você)' : nome,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8B5CF6),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$xp XP',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Banner mostrando sua posição atual
                        if (minhaPosicao > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF682BD7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 30),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Você está em $minhaPosicaoº lugar!',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Continue assim para subir no ranking',
                                        style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.trending_up_rounded, color: Color(0xFF13072E), size: 24),
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