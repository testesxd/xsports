import 'package:flutter/material.dart';

import '../produtos.dart';
import '../api_service.dart';

class SaidaProdutosScreen extends StatefulWidget {
  const SaidaProdutosScreen({super.key});

  @override
  State<SaidaProdutosScreen> createState() => _SaidaProdutosScreenState();
}

class _SaidaProdutosScreenState extends State<SaidaProdutosScreen> {
  static const roxo = Color(0xFF5145E5);

  int? produtoSelecionado;
  final quantidadeController = TextEditingController();
  bool registrando = false;

  String motivo = 'Venda';

  final motivos = ['Venda', 'Troca', 'Uso interno', 'Perda ou avaria'];

  int get quantidadeDisponivel {
    if (produtoSelecionado == null) return 0;

    return (Produtos.lista[produtoSelecionado!]['quantidade'] as num).toInt();
  }

  Future<void> registrarSaida() async {
    if (produtoSelecionado == null) {
      mostrarMensagem('Selecione um produto.');
      return;
    }

    final quantidade = int.tryParse(quantidadeController.text);

    if (quantidade == null || quantidade <= 0) {
      mostrarMensagem('Informe uma quantidade válida.');
      return;
    }

    if (quantidade > quantidadeDisponivel) {
      mostrarMensagem('Quantidade maior que o estoque disponível.');
      return;
    }

    setState(() => registrando = true);
    try {
      final produto = Produtos.lista[produtoSelecionado!];
      final atualizado = await ApiService.registrarSaida(
        produtoId: (produto['id'] as num).toInt(),
        quantidade: quantidade,
        motivo: motivo,
      );
      if (!mounted) return;
      setState(() {
        Produtos.lista[produtoSelecionado!] = atualizado;
        quantidadeController.clear();
        produtoSelecionado = null;
        motivo = 'Venda';
      });
      mostrarMensagem('Saída registrada com sucesso!');
    } on ApiException catch (error) {
      if (!mounted) return;
      mostrarMensagem(error.message);
    } finally {
      if (mounted) setState(() => registrando = false);
    }
  }

  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  void dispose() {
    quantidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saída de Produtos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Registrar saída',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Informe os dados para retirar produtos do estoque.',
              style: TextStyle(color: cores.onSurfaceVariant),
            ),
            const SizedBox(height: 28),

            const Text(
              'Produto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              initialValue: produtoSelecionado,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
                hintText: 'Selecione um produto',
              ),
              items: List.generate(Produtos.lista.length, (index) {
                final produto = Produtos.lista[index];

                return DropdownMenuItem(
                  value: index,
                  child: Text(
                    produto['nome'].toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              onChanged: (valor) {
                setState(() {
                  produtoSelecionado = valor;
                });
              },
            ),

            const SizedBox(height: 20),

            if (produtoSelecionado != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: roxo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_outlined, color: roxo, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quantidade disponível',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quantidadeDisponivel unidades',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: roxo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            const Text(
              'Quantidade de saída',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: quantidadeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ex.: 2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Motivo da saída',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: motivo,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              items: motivos.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (valor) {
                if (valor != null) {
                  setState(() {
                    motivo = valor;
                  });
                }
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: registrando ? null : registrarSaida,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Registrar saída',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: roxo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
