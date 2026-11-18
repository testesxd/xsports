import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../api_service.dart';

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
  final imagePicker = ImagePicker();

  String categoria = 'Unissex';
  Uint8List? fotoBytes;
  String? fotoNome;

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

  Future<void> selecionarFoto() async {
    final origem = await showDialog<ImageSource>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Escolher foto'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Galeria'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Câmera'),
          ),
        ],
      ),
    );
    if (origem == null) return;

    try {
      final arquivo = await imagePicker.pickImage(
        source: origem,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (arquivo == null) return;

      final bytes = await arquivo.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A foto deve ter no máximo 5 MB.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        fotoBytes = bytes;
        fotoNome = arquivo.name;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar a foto: ${error.message ?? error.code}')),
      );
    }
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
        quantidade < 0 ||
        (!editando && fotoBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha os campos com valores válidos e selecione uma foto.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'nome': nome,
      'preco': preco,
      'categoria': categoria,
      'quantidade': quantidade,
      'fotoBytes': fotoBytes,
      'fotoNome': fotoNome,
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

          const SizedBox(height: 20),

          Text(
            'Foto do produto${editando ? ' (opcional)' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cores.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cores.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cores.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: fotoBytes != null
                ? Image.memory(fotoBytes!, fit: BoxFit.contain)
                : _imagemExistente(cores),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: selecionarFoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(fotoBytes == null ? 'Selecionar foto' : 'Trocar foto'),
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

  Widget _imagemExistente(ColorScheme cores) {
    final imagemUrl = ApiService.urlImagem(
      widget.produto?['imagemUrl']?.toString(),
    );
    if (imagemUrl == null) {
      return Center(
        child: Icon(
          Icons.image_outlined,
          size: 56,
          color: cores.onSurfaceVariant,
        ),
      );
    }
    return Image.network(
      imagemUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 56,
          color: cores.onSurfaceVariant,
        ),
      ),
    );
  }
}