import 'package:flutter/material.dart';
import '../theme_controller.dart';
import '../notificacoes_controller.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  static const roxoBotao = Color(0xFF5145E5);

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Preferências',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cores.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: temaEscuro,
                  builder: (context, escuro, child) {
                    return SwitchListTile(
                      secondary: Icon(
                        escuro ? Icons.dark_mode : Icons.light_mode,
                        color: roxoBotao,
                      ),
                      title: const Text('Modo escuro'),
                      subtitle: Text(escuro ? 'Ativado' : 'Desativado'),
                      value: escuro,
                      onChanged: (valor) {
                        temaEscuro.value = valor;
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                ValueListenableBuilder<bool>(
                  valueListenable: notificacoesAtivas,
                  builder: (context, ativas, child) {
                    return SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_none,
                        color: roxoBotao,
                      ),
                      title: const Text('Notificações'),
                      subtitle: Text(
                        ativas
                            ? 'Avisos de estoque baixo ativados'
                            : 'Avisos desativados',
                      ),
                      value: ativas,
                      onChanged: (valor) {
                        notificacoesAtivas.value = valor;
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: roxoBotao,
                  ),
                  title: Text('Sobre o Xsports'),
                  subtitle: Text(
                    'Sistema de gerenciamento de estoque',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}