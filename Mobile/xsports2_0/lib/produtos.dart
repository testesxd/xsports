import 'api_service.dart';

class Produtos {
  static final List<Map<String, dynamic>> lista = [];

  static Future<void> carregar() async {
    final produtos = await ApiService.carregarProdutos();
    lista
      ..clear()
      ..addAll(produtos);
  }
}
