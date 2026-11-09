import 'package:flutter/material.dart';

class CadastroScreen extends StatefulWidget {
  final Map<String, dynamic>? produto;

  const CadastroScreen({
    super.key,
    this.produto,
  });

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final nomeController = TextEditingController();
  final precoController = TextEditingController();
  final quantidadeController = TextEditingController();

  String categoria = 'Unissex';

  static const roxo = Color(0xFF5145E5);

  bool get editando => widget.produto != null;

  @override
  void initState() {
    super.initState();

    final produto = widget.produto;

    if (produto != null) {
      nomeController.text = produto['nome']?.toString() ?? '';
      precoController.text = produto['preco']?.toString() ?? '';
      quantidadeController.text =
          produto['quantidade']?.toString() ?? '';

      const categorias = [
        'Masculino',
        'Feminino',
        'Infantil',
        'Unissex',
      ];

      final categoriaExistente = produto['categoria']?.toString();

      if (categorias.contains(categoriaExistente)) {
        categoria = categoriaExistente!;
      }
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    precoController.dispose();
    quantidadeController.dispose();
    super.dispose();
  }

  void salvarProduto() {
    final nome = nomeController.text.trim();
    final precoTexto =
        precoController.text.trim().replaceAll(',', '.');
    final quantidadeTexto = quantidadeController.text.trim();

    final preco = double.tryParse(precoTexto);
    final quantidade = int.tryParse(quantidadeTexto);

    if (nome.isEmpty ||
        preco == null ||
        preco <= 0 ||
        quantidade == null ||
        quantidade < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha os campos com valores válidos.'),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'nome': nome,
      'preco': preco,
      'categoria': categoria,
      'quantidade': quantidade,
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = tema.colorScheme;

    return Scaffold(
      backgroundColor: cores.surface,

      appBar: AppBar(
        title: Text(
          editando ? 'Editar produto' : 'Cadastrar produto',
        ),
        backgroundColor: const Color(0xFF32105B),
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            editando ? 'Editar produto' : 'Novo produto',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: cores.onSurface,
            ),
          ),

          const SizedBox(height: 24),

          TextField(
            controller: nomeController,
            style: TextStyle(color: cores.onSurface),
            decoration: InputDecoration(
              labelText: 'Nome do produto',
              hintText: 'Ex.: Camiseta esportiva',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: cores.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: precoController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: TextStyle(color: cores.onSurface),
            decoration: InputDecoration(
              labelText: 'Preço (R\$)',
              hintText: 'Ex.: 79,90',
              prefixIcon: const Icon(Icons.attach_money),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: cores.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: categoria,
            dropdownColor: cores.surface,
            style: TextStyle(color: cores.onSurface),
            decoration: InputDecoration(
              labelText: 'Categoria',
              prefixIcon: const Icon(Icons.category_outlined),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: cores.surfaceContainerHighest,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Masculino',
                child: Text('Masculino'),
              ),
              DropdownMenuItem(
                value: 'Feminino',
                child: Text('Feminino'),
              ),
              DropdownMenuItem(
                value: 'Infantil',
                child: Text('Infantil'),
              ),
              DropdownMenuItem(
                value: 'Unissex',
                child: Text('Unissex'),
              ),
            ],
            onChanged: (valor) {
              if (valor != null) {
                setState(() => categoria = valor);
              }
            },
          ),

          const SizedBox(height: 16),

          TextField(
            controller: quantidadeController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: cores.onSurface),
            decoration: InputDecoration(
              labelText: 'Quantidade',
              hintText: 'Ex.: 10',
              prefixIcon: const Icon(Icons.numbers),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: cores.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: salvarProduto,
              icon: Icon(
                editando ? Icons.save_outlined : Icons.add,
              ),
              label: Text(
                editando ? 'Salvar alterações' : 'Cadastrar produto',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: roxo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}