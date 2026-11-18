import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client_factory.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://xsports.onrender.com',
  );
  static final http.Client _client = createApiClient();
  static String? _accessToken;

  static Uri _uri(String path) =>
      Uri.parse('${_baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/$path');

  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final response = await _send(
      'POST',
      'auth/login',
      body: {'email': email, 'senha': senha},
      authenticated: false,
    );
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    final token = result['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('O servidor não retornou um token de acesso.');
    }
    _accessToken = token;
    return result;
  }

  static Future<void> logout() async {
    _accessToken = null;
  }

  static Future<List<Map<String, dynamic>>> carregarProdutos() async {
    final response = await _send('GET', 'produtos');
    final produtos = jsonDecode(response.body) as List<dynamic>;
    return produtos
        .map((item) => _produtoMobile(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> carregarMovimentacoes() async {
    final response = await _send('GET', 'movimentacoes');
    final movimentacoes = jsonDecode(response.body) as List<dynamic>;
    return movimentacoes.map((item) => item as Map<String, dynamic>).toList();
  }

  static String? urlImagem(String? imagemUrl) {
    if (imagemUrl == null || imagemUrl.isEmpty) return null;
    final uri = Uri.tryParse(imagemUrl);
    if (uri == null) return null;
    return uri.hasScheme
        ? uri.toString()
        : Uri.parse(_baseUrl).resolveUri(uri).toString();
  }

  static Future<Map<String, dynamic>> criarProduto(
    Map<String, dynamic> produto, {
    List<int>? imageBytes,
    String? imageName,
  }) async {
    final response = imageBytes == null
        ? await _send('POST', 'produtos', body: _produtoApi(produto))
        : await _sendMultipart(
            'POST',
            'produtos/upload',
            fields: _produtoFields(produto),
            imageBytes: imageBytes,
            imageName: imageName ?? 'produto.jpg',
          );
    return _produtoMobile(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> atualizarProduto(
    int id,
    Map<String, dynamic> produto, {
    List<int>? imageBytes,
    String? imageName,
  }) async {
    final response = imageBytes == null
        ? await _send('PUT', 'produtos/$id', body: _produtoApi(produto))
        : await _sendMultipart(
            'PUT',
            'produtos/$id/upload',
            fields: _produtoFields(produto),
            imageBytes: imageBytes,
            imageName: imageName ?? 'produto.jpg',
          );
    return _produtoMobile(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> excluirProduto(int id) async {
    await _send('DELETE', 'produtos/$id');
  }

  static Future<Map<String, dynamic>> registrarSaida({
    required int produtoId,
    required int quantidade,
    required String motivo,
  }) async {
    final response = await _send(
      'POST',
      'movimentacoes',
      body: {
        'produtoId': produtoId,
        'quantidade': quantidade,
        'motivo': motivo,
      },
    );
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return _produtoMobile(result['produto'] as Map<String, dynamic>);
  }

  static Map<String, dynamic> _produtoApi(Map<String, dynamic> produto) => {
    'nome': produto['nome'],
    'preco': produto['preco'],
    'quantidade': produto['quantidade'],
    'categoria': produto['categoria'],
    'imagemUrl': produto['imagemUrl'],
  };

  static Map<String, String> _produtoFields(Map<String, dynamic> produto) => {
    'nome': produto['nome'].toString(),
    'preco': produto['preco'].toString(),
    'quantidade': produto['quantidade'].toString(),
    'categoria': produto['categoria'].toString(),
  };

  static Map<String, dynamic> _produtoMobile(Map<String, dynamic> produto) => {
    'id': produto['id'],
    'nome': produto['nome'],
    'preco': produto['preco'],
    'quantidade': produto['quantidade'],
    'categoria': produto['categoria'],
    'imagemUrl': produto['imagemUrl'],
  };

  static Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{};
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (authenticated) {
      if (_accessToken == null) {
        throw const ApiException('Faça login para continuar.');
      }
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    late final http.Response response;
    try {
      final request = http.Request(method, _uri(path))..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      response = await http.Response.fromStream(await _client.send(request));
    } on http.ClientException catch (error) {
      throw ApiException('Não foi possível conectar ao servidor: $error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response));
    }

    return response;
  }

  static Future<http.Response> _sendMultipart(
    String method,
    String path, {
    required Map<String, String> fields,
    required List<int> imageBytes,
    required String imageName,
  }) async {
    if (_accessToken == null) {
      throw const ApiException('Faça login para continuar.');
    }

    late final http.Response response;
    try {
      final request = http.MultipartRequest(method, _uri(path))
        ..headers['Authorization'] = 'Bearer $_accessToken'
        ..fields.addAll(fields)
        ..files.add(
          http.MultipartFile.fromBytes('foto', imageBytes, filename: imageName),
        );
      response = await http.Response.fromStream(await _client.send(request));
    } on http.ClientException catch (error) {
      throw ApiException('Não foi possível conectar ao servidor: $error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response));
    }

    return response;
  }

  static String _errorMessage(http.Response response) {
    if (response.statusCode == 401) {
      return 'E-mail ou senha inválidos, ou sessão expirada.';
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'] ?? body['title'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      final errors = body['errors'];
      if (errors is Map<String, dynamic>) {
        final messages = errors.values
            .whereType<List<dynamic>>()
            .expand((items) => items)
            .whereType<String>()
            .toList();
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    } on FormatException {
      if (response.body.isNotEmpty) {
        return response.body;
      }
    }
    return 'Falha na comunicação com o servidor (${response.statusCode}).';
  }
}
