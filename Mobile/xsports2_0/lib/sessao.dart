class Sessao {
  static String nome = 'Administrador';
  static String email = '';
  static String empresa = 'Xsports';
  static String tipoConta = 'Administrador';

  static bool ativa = false;

  static void iniciar({
    required String emailUsuario,
  }) {
    email = emailUsuario;
    ativa = true;
  }

  static void encerrar() {
    nome = 'Administrador';
    email = '';
    empresa = 'Xsports';
    tipoConta = 'Administrador';
    ativa = false;
  }
}