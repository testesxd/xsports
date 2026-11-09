import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme_controller.dart';
import 'sessao.dart';
import 'api_service.dart';
import 'produtos.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const roxo = Color(0xFF5145E5);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: temaEscuro,
      builder: (context, escuro, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Xsports',
          themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: roxo,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: roxo,
              brightness: Brightness.dark,
            ),
          ),
          home: const LoginScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usuarioController = TextEditingController();
  final senhaController = TextEditingController();

  bool ocultarSenha = true;
  bool entrando = false;

  @override
  void dispose() {
    usuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    final usuario = usuarioController.text.trim();
    final senha = senhaController.text;

    if (usuario.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o e-mail e a senha.')),
      );
      return;
    }

    setState(() => entrando = true);
    try {
      final perfil = await ApiService.login(usuario, senha);
      Sessao.nome = perfil['nome'] as String;
      Sessao.iniciar(emailUsuario: perfil['email'] as String);
      await Produtos.carregar();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final escuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: cores.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cores.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: escuro
                              ? const Color(0xFF302B50)
                              : const Color(0xFFF0F1FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF5145E5),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Xsports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cores.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entre com suas credenciais de administrador',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'E-mail',
                          style: TextStyle(color: cores.onSurface),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: usuarioController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'admin@xsports.com',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Senha',
                          style: TextStyle(color: cores.onSurface),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: senhaController,
                        obscureText: ocultarSenha,
                        decoration: InputDecoration(
                          hintText: 'Digite sua senha',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                ocultarSenha = !ocultarSenha;
                              });
                            },
                            icon: Icon(
                              ocultarSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: entrando ? null : entrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5145E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: entrando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Entrar no Sistema',
                                  style: TextStyle(fontSize: 13),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'PIM - Análise e Desenvolvimento de Sistemas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: cores.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
