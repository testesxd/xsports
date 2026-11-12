<div align="center">

# Xsports

**Gestao de estoque para produtos esportivos**

Aplicacao web e mobile para acompanhar produtos, quantidades em estoque e movimentacoes de saida, com persistencia em MySQL.

[Recursos](#recursos) | [Tecnologias](#tecnologias) | [Executar](#executar-localmente) | [API](#api)

</div>

---

## Sobre o projeto

O Xsports e um sistema desenvolvido como projeto academico de Analise e Desenvolvimento de Sistemas. O repositorio inclui uma aplicacao web em ASP.NET Core e um cliente Flutter que consome a API do backend.

## Recursos

- Cadastro, edicao, consulta e remocao de produtos.
- Organizacao do catalogo por categoria, com busca por nome.
- Registro de saidas e consulta ao historico de movimentacoes.
- Alertas para produtos com estoque baixo.
- Login de administrador na aplicacao web e autenticacao JWT na API mobile.
- Interface responsiva com tema claro e escuro.
- Validacao para impedir preco zero ou negativo, estoque negativo e saida acima do saldo disponivel.

## Tecnologias

| Camada | Tecnologias |
| --- | --- |
| Backend e web | .NET 10, ASP.NET Core Razor Pages, C# |
| Persistencia | Entity Framework Core, Pomelo e MySQL/MariaDB |
| Autenticacao da API | JWT Bearer |
| Aplicativo | Flutter e Dart |
| Interface web | Razor, Tailwind CSS e Lucide |

## Requisitos

- .NET SDK 10.
- MySQL ou MariaDB acessivel pela maquina.
- Flutter SDK compativel com Dart 3.13 ou superior, para executar o aplicativo.

## Executar localmente

### 1. Configurar o banco

Crie um banco MySQL/MariaDB e configure a string de conexao por variavel de ambiente. No PowerShell, substitua os valores de exemplo pelos dados locais:

```powershell
$env:ConnectionStrings__DefaultConnection = "Server=localhost;Database=xsports_db;User=SEU_USUARIO;Password=SUA_SENHA;"
```

Na inicializacao, o backend chama `EnsureCreated` para criar o banco e as tabelas quando necessario. O script de estrutura de referencia fica em `Banco/xsports banco.sql`.

### 2. Configurar a chave JWT

A API exige uma chave com pelo menos 32 bytes. Gere uma chave aleatoria para desenvolvimento no PowerShell:

```powershell
$bytes = [byte[]]::new(32)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$env:Jwt__Key = [Convert]::ToBase64String($bytes)
```

Mantenha a chave e a senha do banco fora do codigo-fonte. Em producao, use o gerenciador de segredos da plataforma de hospedagem e configure `Cors__AllowedOrigins` com as origens autorizadas.

### 3. Iniciar o backend

Na raiz do repositorio, no mesmo terminal em que as variaveis de ambiente foram definidas:

```powershell
$env:PORT = "5048"
dotnet restore
dotnet run --project .\Xsports.csproj
```

O site fica disponivel em `http://localhost:5048`. O endpoint de login redireciona para a pagina de autenticacao; use uma conta de administrador existente no banco.

### 4. Iniciar o app Flutter (opcional)

Abra outro terminal:

```powershell
Set-Location .\Mobile\xsports2_0
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:5048
```

Para executar em um dispositivo Android, configure `API_BASE_URL` com um endereco HTTPS acessivel pelo dispositivo. O cliente mobile usa a mesma API e o mesmo banco do backend; nao se conecta diretamente ao banco de dados.

## API

A API esta disponivel sob `/api`. O endpoint de autenticacao e publico; os demais exigem um token JWT no cabecalho `Authorization: Bearer <token>`.

| Metodo | Rota | Acesso | Descricao |
| --- | --- | --- | --- |
| `POST` | `/api/auth/login` | Publico | Autentica o usuario e retorna um token. |
| `GET` | `/api/produtos` | JWT | Lista os produtos. |
| `POST` | `/api/produtos` | JWT | Cadastra um produto. |
| `PUT` | `/api/produtos/{id}` | JWT | Atualiza um produto. |
| `DELETE` | `/api/produtos/{id}` | JWT | Remove um produto. |
| `POST` | `/api/movimentacoes` | JWT | Registra uma saida de estoque. |

## Estrutura do repositorio

```text
.
|-- Api/                     # Endpoints REST e servico JWT
|-- Banco/                   # Script SQL de referencia
|-- Migrations/              # Historico de migrations do EF Core
|-- Models/                  # Modelos de dominio
|-- Pages/                   # Paginas Razor da aplicacao web
|-- Mobile/xsports2_0/        # Aplicativo Flutter
|-- wwwroot/                 # CSS, imagens e arquivos estaticos
|-- Program.cs               # Configuracao e inicializacao do backend
`-- Xsports.csproj           # Projeto ASP.NET Core
```

## Container

O repositorio inclui um `Dockerfile` para construir e executar o backend em container. Configure as variaveis `ConnectionStrings__DefaultConnection` e `Jwt__Key` no ambiente do container antes de iniciar. A aplicacao escuta na porta `10000` por padrao no container.
