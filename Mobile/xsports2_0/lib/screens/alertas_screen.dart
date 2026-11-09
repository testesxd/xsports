
import 'package:flutter/material.dart';
import '../produtos.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  static const roxoBotao = Color(0xFF5145E5);

  String statusEstoque(int quantidade) {
    if (quantidade < 5) {
      return 'Repor estoque';
    }
    return 'Estoque baixo';
  }

  Color corStatus(int quantidade) {
    if (quantidade < 5) {
      return Colors.red;
    }
    return Colors.orange;
  }

  IconData iconeStatus(int quantidade) {
    if (quantidade < 5) {
      return Icons.error_outline;
    }
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    final alertas = Produtos.lista.where((produto) {
      final quantidade = (produto['quantidade'] as num).toInt();
      return quantidade < 20;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
      ),
      body: alertas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 64,
                      color: cores.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tudo em dia!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cores.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhum produto precisa de atenção no momento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cores.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Produtos que precisam de atenção: ${alertas.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cores.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ...alertas.map((produto) {
                  final quantidade =
                      (produto['quantidade'] as num).toInt();
                  final cor = corStatus(quantidade);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cor.withValues(alpha: 0.15),
                        child: Icon(
                          iconeStatus(quantidade),
                          color: cor,
                        ),
                      ),
                      title: Text(
                        produto['nome'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Quantidade disponível: $quantidade'
                        '\n${statusEstoque(quantidade)}',
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        Icons.notifications_active_outlined,
                        color: cor,
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
