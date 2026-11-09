import 'package:flutter/material.dart';

import 'estoque_screen.dart';

import 'cadastro_screen.dart';

import 'alertas_screen.dart';

import 'configuracoes_screen.dart';

import '../produtos.dart';
import '../api_service.dart';

import '../sessao.dart';

import '../notificacoes_controller.dart';

import 'saida_produtos_screen.dart';

import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const roxo = Color(0xFF211B50);

  static const roxoBotao = Color(0xFF5145E5);

  final TextEditingController buscaController = TextEditingController();

  String categoriaSelecionada = 'Todos';

  String situacaoSelecionada = 'Todas';

  int get quantidadeAlertas {
    return Produtos.lista.where((produto) {
      final quantidade = (produto['quantidade'] as num).toInt();

      return quantidade < 20;
    }).length;
  }

  Future<void> abrirTela(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> cadastrarProduto() async {
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,

      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );

    if (!mounted) return;

    if (resultado != null) {
      try {
        final produto = await ApiService.criarProduto(resultado);
        if (!mounted) return;
        setState(() => Produtos.lista.add(produto));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto cadastrado com sucesso!')),
        );
      } on ApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> editarProduto(int index) async {
    final produto = Produtos.lista[index];

    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,

      MaterialPageRoute(builder: (_) => CadastroScreen(produto: produto)),
    );

    if (!mounted) return;

    if (resultado != null) {
      try {
        final id = (produto['id'] as num).toInt();
        final atualizado = await ApiService.atualizarProduto(id, resultado);
        if (!mounted) return;
        setState(() => Produtos.lista[index] = atualizado);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
      } on ApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> excluirProduto(int index) async {
    final produto = Produtos.lista[index];

    final nome = produto['nome']?.toString() ?? 'este produto';

    final confirmar = await showDialog<bool>(
      context: context,

      builder: (context) => AlertDialog(
        title: const Text('Excluir produto'),

        content: Text('Deseja realmente excluir "$nome"?'),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),

            child: const Text('Cancelar'),
          ),

          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,

              foregroundColor: Colors.white,
            ),

            onPressed: () => Navigator.pop(context, true),

            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmar == true) {
      try {
        final id = (produto['id'] as num).toInt();
        await ApiService.excluirProduto(id);
        if (!mounted) return;
        setState(() => Produtos.lista.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto excluído com sucesso!')),
        );
      } on ApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Color corSituacao(int quantidade) {
    if (quantidade >= 20) return Colors.green;

    if (quantidade >= 5) return Colors.orange;

    return Colors.red;
  }

  String textoSituacao(int quantidade) {
    if (quantidade >= 20) return 'Em dia';

    if (quantidade >= 5) return 'Estoque baixo';

    return 'Repor estoque';
  }

  IconData iconeSituacao(int quantidade) {
    if (quantidade >= 20) return Icons.check_circle_outline;

    if (quantidade >= 5) return Icons.warning_amber_rounded;

    return Icons.error_outline;
  }

  List<MapEntry<int, Map<String, dynamic>>> get produtosFiltrados {
    final busca = buscaController.text.trim().toLowerCase();

    return Produtos.lista.asMap().entries.where((entry) {
      final produto = entry.value;

      final nome = produto['nome']?.toString().toLowerCase() ?? '';

      final categoria = produto['categoria']?.toString() ?? '';

      final quantidade = (produto['quantidade'] as num?)?.toInt() ?? 0;

      final correspondeBusca = nome.contains(busca);

      final correspondeCategoria =
          categoriaSelecionada == 'Todos' || categoria == categoriaSelecionada;

      final situacao = textoSituacao(quantidade);

      final correspondeSituacao =
          situacaoSelecionada == 'Todas' || situacao == situacaoSelecionada;

      return correspondeBusca && correspondeCategoria && correspondeSituacao;
    }).toList();
  }

  @override
  void dispose() {
    buscaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    final totalAlertas = quantidadeAlertas;

    final produtos = produtosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xsports',

          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: 'Alertas',

            onPressed: () => abrirTela(const AlertasScreen()),

            icon: Stack(
              clipBehavior: Clip.none,

              children: [
                const Icon(Icons.notifications_none),

                if (notificacoesAtivas.value && totalAlertas > 0)
                  Positioned(
                    right: -7,

                    top: -5,

                    child: Container(
                      padding: const EdgeInsets.all(4),

                      constraints: const BoxConstraints(
                        minWidth: 18,

                        minHeight: 18,
                      ),

                      decoration: const BoxDecoration(
                        color: Colors.red,

                        shape: BoxShape.circle,
                      ),

                      child: Text(
                        totalAlertas > 99 ? '99+' : '$totalAlertas',

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 10,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Configurações',

            icon: const Icon(Icons.settings_outlined),

            onPressed: () => abrirTela(const ConfiguracoesScreen()),
          ),
        ],
      ),

      drawer: Drawer(
        backgroundColor: roxo,

        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Padding(
                padding: EdgeInsets.all(24),

                child: Text(
                  'XSports',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 24,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(color: Colors.white24),

              _itemMenu(Icons.grid_view_rounded, 'Home', true),

              _itemMenu(Icons.inventory_2_outlined, 'Estoque', false),

              _itemMenu(Icons.swap_horiz, 'Saída de Produtos', false),

              _itemMenu(
                Icons.notifications_none,

                notificacoesAtivas.value && totalAlertas > 0
                    ? 'Alertas ($totalAlertas)'
                    : 'Alertas',

                false,
              ),

              const Spacer(),

              const Divider(color: Colors.white24),

              ListTile(
                leading: CircleAvatar(
                  backgroundColor: roxoBotao,

                  child: Text(
                    Sessao.nome.isNotEmpty
                        ? Sessao.nome.trim().substring(0, 1).toUpperCase()
                        : 'A',

                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                title: Text(
                  Sessao.nome,

                  style: const TextStyle(color: Colors.white),
                ),

                subtitle: Text(
                  Sessao.empresa,

                  style: const TextStyle(color: Colors.white70),
                ),

                onTap: () {
                  Navigator.pop(context);

                  abrirTela(const PerfilScreen());
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: cadastrarProduto,

        backgroundColor: roxoBotao,

        foregroundColor: Colors.white,

        icon: const Icon(Icons.add),

        label: const Text('Novo produto'),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'Catálogo de Produtos',

                    style: TextStyle(
                      fontSize: 25,

                      fontWeight: FontWeight.bold,

                      color: cores.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Encontre e gerencie seus produtos.',

                    style: TextStyle(color: cores.onSurfaceVariant),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: buscaController,

                    onChanged: (_) => setState(() {}),

                    decoration: InputDecoration(
                      hintText: 'Buscar produto pelo nome...',

                      prefixIcon: const Icon(Icons.search),

                      suffixIcon: buscaController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpar busca',

                              icon: const Icon(Icons.close),

                              onPressed: () {
                                buscaController.clear();

                                setState(() {});
                              },
                            )
                          : null,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      filled: true,

                      fillColor: cores.surface,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Categoria',

                    style: TextStyle(
                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                      color: cores.onSurface,
                    ),
                  ),

                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    child: Row(
                      children:
                          [
                            'Todos',

                            'Masculino',

                            'Feminino',

                            'Infantil',

                            'Unissex',
                          ].map((categoria) {
                            final selecionada =
                                categoriaSelecionada == categoria;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),

                              child: ChoiceChip(
                                label: Text(categoria),

                                selected: selecionada,

                                showCheckmark: false,

                                selectedColor: roxoBotao,

                                backgroundColor: cores.surface,

                                labelStyle: TextStyle(
                                  color: selecionada
                                      ? Colors.white
                                      : cores.onSurface,
                                ),

                                onSelected: (_) {
                                  setState(() {
                                    categoriaSelecionada = categoria;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Situação do estoque',

                    style: TextStyle(
                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                      color: cores.onSurface,
                    ),
                  ),

                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    child: Row(
                      children:
                          [
                            'Todas',

                            'Em dia',

                            'Estoque baixo',

                            'Repor estoque',
                          ].map((situacao) {
                            final selecionada = situacaoSelecionada == situacao;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),

                              child: ChoiceChip(
                                label: Text(situacao),

                                selected: selecionada,

                                showCheckmark: false,

                                selectedColor: roxoBotao,

                                backgroundColor: cores.surface,

                                labelStyle: TextStyle(
                                  color: selecionada
                                      ? Colors.white
                                      : cores.onSurface,

                                  fontSize: 12,
                                ),

                                onSelected: (_) {
                                  setState(() {
                                    situacaoSelecionada = situacao;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    '${produtos.length} produto(s) encontrado(s)',

                    style: TextStyle(
                      color: cores.onSurfaceVariant,

                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: produtos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),

                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.inventory_2_outlined,

                              size: 58,

                              color: cores.onSurfaceVariant,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              Produtos.lista.isEmpty
                                  ? 'Nenhum produto cadastrado'
                                  : 'Nenhum produto encontrado',

                              textAlign: TextAlign.center,

                              style: TextStyle(
                                fontSize: 18,

                                fontWeight: FontWeight.bold,

                                color: cores.onSurface,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              Produtos.lista.isEmpty
                                  ? 'Cadastre um produto para vê-lo aqui.'
                                  : 'Tente alterar a busca ou os filtros.',

                              textAlign: TextAlign.center,

                              style: TextStyle(color: cores.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final largura = constraints.maxWidth;

                        final colunas = largura >= 900
                            ? 3
                            : largura >= 560
                            ? 2
                            : 1;

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),

                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: colunas,

                                crossAxisSpacing: 14,

                                mainAxisSpacing: 14,

                                mainAxisExtent: colunas == 1 ? 230 : 250,
                              ),

                          itemCount: produtos.length,

                          itemBuilder: (context, indice) {
                            final entry = produtos[indice];

                            final indexOriginal = entry.key;

                            final produto = entry.value;

                            final nome =
                                produto['nome']?.toString() ?? 'Produto';

                            final categoria =
                                produto['categoria']?.toString() ?? '';

                            final preco =
                                (produto['preco'] as num?)?.toDouble() ?? 0;

                            final quantidade =
                                (produto['quantidade'] as num?)?.toInt() ?? 0;

                            final cor = corSituacao(quantidade);

                            return Card(
                              clipBehavior: Clip.antiAlias,

                              elevation: 1,

                              color: cores.surface,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),

                                side: BorderSide(color: cores.outlineVariant),
                              ),

                              child: Padding(
                                padding: const EdgeInsets.all(14),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Container(
                                          width: 52,

                                          height: 52,

                                          decoration: BoxDecoration(
                                            color: roxoBotao.withValues(
                                              alpha: 0.10,
                                            ),

                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),

                                          child: const Icon(
                                            Icons.checkroom_outlined,

                                            size: 30,

                                            color: roxoBotao,
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              Text(
                                                nome,

                                                maxLines: 2,

                                                overflow: TextOverflow.ellipsis,

                                                style: TextStyle(
                                                  fontSize: 16,

                                                  fontWeight: FontWeight.bold,

                                                  color: cores.onSurface,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              Text(
                                                categoria,

                                                style: TextStyle(
                                                  color: cores.onSurfaceVariant,

                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    Text(
                                      'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}',

                                      style: const TextStyle(
                                        color: roxoBotao,

                                        fontSize: 21,

                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Row(
                                      children: [
                                        Icon(
                                          iconeSituacao(quantidade),

                                          color: cor,

                                          size: 18,
                                        ),

                                        const SizedBox(width: 6),

                                        Expanded(
                                          child: Text(
                                            'Quantidade: $quantidade',

                                            style: TextStyle(
                                              color: cores.onSurface,

                                              fontSize: 13,
                                            ),
                                          ),
                                        ),

                                        Flexible(
                                          child: Text(
                                            textoSituacao(quantidade),

                                            textAlign: TextAlign.end,

                                            style: TextStyle(
                                              color: cor,

                                              fontWeight: FontWeight.bold,

                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Spacer(),

                                    const Divider(height: 16),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,

                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              editarProduto(indexOriginal),

                                          icon: const Icon(
                                            Icons.edit_outlined,

                                            size: 18,
                                          ),

                                          label: const Text('Editar'),
                                        ),

                                        const SizedBox(width: 4),

                                        TextButton.icon(
                                          onPressed: () =>
                                              excluirProduto(indexOriginal),

                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),

                                          icon: const Icon(
                                            Icons.delete_outline,

                                            size: 18,
                                          ),

                                          label: const Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemMenu(IconData icone, String titulo, bool selecionado) {
    return ListTile(
      leading: Icon(icone, color: selecionado ? Colors.white : Colors.white70),

      title: Text(
        titulo,

        style: TextStyle(
          color: Colors.white,

          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
        ),
      ),

      selected: selecionado,

      selectedTileColor: roxoBotao,

      onTap: () {
        Navigator.pop(context);

        if (titulo == 'Estoque') {
          abrirTela(const EstoqueScreen());
        } else if (titulo.startsWith('Alertas')) {
          abrirTela(const AlertasScreen());
        } else if (titulo == 'Saída de Produtos') {
          abrirTela(const SaidaProdutosScreen());
        }
      },
    );
  }
}
