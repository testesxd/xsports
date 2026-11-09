# Xsports mobile

O app usa a API do projeto ASP.NET Core, que persiste os dados no mesmo MySQL
configurado em `ConnectionStrings:DefaultConnection`. O Flutter não se conecta
diretamente ao banco nem armazena as credenciais dele.

## Executar localmente

1. Configure a conexão MySQL do backend por meio de `ConnectionStrings:DefaultConnection`
   ou da variável `ConnectionStrings__DefaultConnection`.
2. Configure uma chave JWT aleatória com pelo menos 32 bytes. Não use a chave
   de desenvolvimento em produção nem a inclua no app Flutter:

   ```powershell
   $bytes = [byte[]]::new(32)
   [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
   $env:Jwt__Key = [Convert]::ToBase64String($bytes)
   ```

3. Inicie o backend na porta `5048` no mesmo terminal:

   ```powershell
   $env:PORT = "5048"
   dotnet run --project ..\..\Xsports.csproj
   ```

4. Em outro terminal, inicie o app web:

   ```powershell
   flutter run -d chrome --web-port 5173 `
     --dart-define=API_BASE_URL=http://localhost:5048
   ```

O login usa os mesmos usuários e senhas do site. A API permite origens Flutter
locais para desenvolvimento; em produção, configure `Cors:AllowedOrigins` com
as origens exatas da aplicação. Para Android, defina `API_BASE_URL` para um
endereço HTTPS acessível pelo dispositivo. O token bearer expira em 60 minutos;
o app o mantém apenas em memória e solicita novo login quando a sessão expira.
