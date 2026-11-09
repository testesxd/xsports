import 'package:flutter/material.dart';

import 'cadastro_screen.dart';
import '../produtos.dart';
import '../api_service.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  static const Color roxo = Color(0xFF54218A);
  static const Color roxoEscuro = Color(0xFF32105B);

  final TextEditingController buscaController = TextEditingController();

  String categoriaSelecionada = 'Todas';
  String situacaoSelecionada = 'Todas';

  List<Map<String, dynamic>> get produtos => Produtos.lista;

  List<Map<String, dynamic>> get produtosFiltrados {
    final busca = buscaController.text.trim().toLowerCase();

    return produtos.where((produto) {
      final nome = (produto['nome'] ?? '').toString().toLowerCase();
      final categoria = (produto['categoria'] ?? '').toString();
      final quantidade = (produto['quantidade'] as num).toInt();

      final correspondeNome = nome.contains(busca);

      final correspondeCategoria =
          categoriaSelecionada == 'Todas' || categoria == categoriaSelecionada;

      final situacao = statusEstoque(quantidade);

      final correspondeSituacao =
          situacaoSelecionada == 'Todas' || situacao == situacaoSelecionada;

      return correspondeNome && correspondeCategoria && correspondeSituacao;
    }).toList();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> abrirCadastro() async {
    final produto = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CadastroScreen()),
    );

    if (!mounted || produto == null) return;

    try {
      final salvo = await ApiService.criarProduto(produto);
      if (!mounted) return;
      setState(() => Produtos.lista.add(salvo));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${salvo['nome']} foi adicionado ao estoque!')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> editarProduto(int index) async {
    final produtoAtual = produtos[index];

    final produtoEditado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroScreen(produto: produtoAtual),
      ),
    );

    if (!mounted || produtoEditado == null) return;
    if (index >= produtos.length) return;

    try {
      final id = (produtoAtual['id'] as num).toInt();
      final salvo = await ApiService.atualizarProduto(id, produtoEditado);
      if (!mounted) return;
      setState(() => Produtos.lista[index] = salvo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${salvo['nome']} foi atualizado com sucesso!')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> excluirProduto(int index) async {
    final produto = produtos[index];
    final nome = produto['nome']?.toString() ?? 'este produto';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text(
          'Tem certeza de que deseja excluir "$nome" do estoque? '
          'Essa ação não poderá ser desfeita.',
        ),
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

    if (!mounted || confirmar != true) return;
    if (index >= produtos.length) return;

    try {
      final id = (produto['id'] as num).toInt();
      await ApiService.excluirProduto(id);
      if (!mounted) return;
      setState(() => Produtos.lista.removeAt(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$nome foi removido do estoque.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  String statusEstoque(int quantidade) {
    if (quantidade >= 20) {
      return 'Em dia';
    } else if (quantidade >= 5) {
      return 'Estoque baixo';
    } else {
      return 'Repor estoque';
    }
  }

  Color corStatus(int quantidade) {
    if (quantidade >= 20) {
      return Colors.green;
    } else if (quantidade >= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData iconeStatus(int quantidade) {
    if (quantidade >= 20) {
      return Icons.check_circle;
    } else if (quantidade >= 5) {
      return Icons.warning_amber_rounded;
    } else {
      return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final listaFiltrada = produtosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Estoque'),
        backgroundColor: roxoEscuro,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerenciamento de Estoque',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cores.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesquise e filtre os produtos do inventário.',
              style: TextStyle(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: abrirCadastro,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Produto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: roxo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: buscaController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Buscar produto pelo nome',
                hintText: 'Ex.: Camiseta',
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
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: categoriaSelecionada,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar por categoria',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Todas',
                  child: Text('Todas as categorias'),
                ),
                DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                DropdownMenuItem(value: 'Infantil', child: Text('Infantil')),
                DropdownMenuItem(value: 'Unissex', child: Text('Unissex')),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => categoriaSelecionada = valor);
                }
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: situacaoSelecionada,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar por situação',
                prefixIcon: Icon(Icons.inventory_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Todas',
                  child: Text('Todas as situações'),
                ),
                DropdownMenuItem(value: 'Em dia', child: Text('Em dia')),
                DropdownMenuItem(
                  value: 'Estoque baixo',
                  child: Text('Estoque baixo'),
                ),
                DropdownMenuItem(
                  value: 'Repor estoque',
                  child: Text('Repor estoque'),
                ),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => situacaoSelecionada = valor);
                }
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Exibindo ${listaFiltrada.length} de ${produtos.length} produtos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cores.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    buscaController.clear();
                    setState(() {
                      categoriaSelecionada = 'Todas';
                      situacaoSelecionada = 'Todas';
                    });
                  },
                  child: const Text('Limpar filtros'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: produtos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 72,
                            color: cores.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum produto cadastrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cores.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cadastre seu primeiro produto!',
                            style: TextStyle(color: cores.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : listaFiltrada.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: cores.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum produto encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cores.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente mudar a busca ou os filtros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cores.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        final produto = listaFiltrada[index];

                        // Recupera a posição original do produto.
                        final indiceOriginal = Produtos.lista.indexOf(produto);

                        final preco = (produto['preco'] as num).toDouble();
                        final quantidade = (produto['quantidade'] as num)
                            .toInt();
                        final cor = corStatus(quantidade);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cor.withValues(alpha: 0.15),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: cor,
                              ),
                            ),
                            title: Text(
                              produto['nome'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${produto['categoria']}'
                                '\nPreço: R\$ ${preco.toStringAsFixed(2)}'
                                '\nQuantidade: $quantidade unidades'
                                '\nStatus: ${statusEstoque(quantidade)}',
                              ),
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(iconeStatus(quantidade), color: cor),
                                IconButton(
                                  tooltip: 'Editar produto',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: roxo,
                                  ),
                                  onPressed: indiceOriginal < 0
                                      ? null
                                      : () => editarProduto(indiceOriginal),
                                ),
                                IconButton(
                                  tooltip: 'Excluir produto',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: indiceOriginal < 0
                                      ? null
                                      : () => excluirProduto(indiceOriginal),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
