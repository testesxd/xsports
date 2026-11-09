import 'package:flutter/material.dart';

import '../sessao.dart';
import '../api_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  static const roxo = Color(0xFF5145E5);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String tipoContaSelecionado = Sessao.tipoConta;

  void salvarTipoConta(String? novoTipo) {
    if (novoTipo == null) return;

    setState(() {
      tipoContaSelecionado = novoTipo;
      Sessao.tipoConta = novoTipo;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tipo de conta atualizado com sucesso!')),
    );
  }

  Future<void> sair() async {
    try {
      await ApiService.logout();
    } on ApiException catch (error) {
      if (error.message != 'E-mail ou senha inválidos, ou sessão expirada.') {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
    }

    if (!mounted) return;
    Sessao.encerrar();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: PerfilScreen.roxo,
                  child: Icon(Icons.person, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  Sessao.nome,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  tipoContaSelecionado,
                  style: TextStyle(color: cores.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('E-mail'),
                        subtitle: Text(
                          Sessao.email.isEmpty ? 'Não informado' : Sessao.email,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.business_outlined),
                        title: const Text('Empresa'),
                        subtitle: Text(Sessao.empresa),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tipo de conta',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: tipoContaSelecionado,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Administrador',
                                        child: Text('Administrador'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Atendente',
                                        child: Text('Atendente'),
                                      ),
                                    ],
                                    onChanged: salvarTipoConta,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: sair,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da conta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
