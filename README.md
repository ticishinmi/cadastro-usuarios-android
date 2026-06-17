# Cadastro de Usuários

Aplicação Flutter para cadastro, edição, exclusão e consulta de usuários, com persistência em banco de dados PostgreSQL via API REST em Dart.

---

## Tecnologias utilizadas

- **Flutter** — interface mobile (Android) e web (Chrome)
- **Dart** — linguagem principal e servidor REST
- **PostgreSQL** — banco de dados relacional
- **Shelf** — servidor HTTP em Dart
- **HTTP** — comunicação entre o app e a API

---

## Funcionalidades

- Listar usuários em ordem alfabética
- Cadastrar novo usuário (nome, idade e sexo)
- Editar usuário existente
- Excluir usuário com confirmação
- Filtrar usuários por nome em tempo real
- Navegação por teclado no formulário (Enter avança o campo, setas navegam no dropdown)
- Foco automático no primeiro campo inválido ao salvar
- Conexão com banco de dados PostgreSQL

---

## Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (já incluído no Flutter)
- [PostgreSQL](https://www.postgresql.org/download/) instalado e rodando
- [Git](https://git-scm.com/download/win)

---

## Configuração do banco de dados

As configurações de conexão estão no arquivo `server.dart`:

| Parâmetro | Valor         |
|-----------|---------------|
| Host      | localhost     |
| Porta     | 5432          |
| Banco     | banco         |
| Usuário   | postgres      |
| Senha     | admin         |

A tabela `usuarios` é criada automaticamente ao iniciar o servidor.

---

## Instalação

**1. Clone o repositório:**
```bash
git clone https://github.com/ticishinmi/cadastro-usuarios.git
cd cadastro-usuarios
```

**2. Instale as dependências:**
```bash
flutter pub get
dart pub add shelf shelf_router postgres
```

---

## Como rodar

**1. Inicie o servidor** (deixe este terminal aberto):
```bash
dart run server.dart
```
O servidor ficará disponível em `http://localhost:8080`.

**2. Rode o app** em outro terminal:

- **Web (Chrome):**
```bash
flutter run -d chrome
```

- **Android (emulador):**
```bash
flutter run
```

> No emulador Android o app se conecta via `http://10.0.2.2:8080` — endereço especial que aponta para o `localhost` do computador host.

---

## Estrutura do projeto

```
cadastro-usuarios/
├── lib/
│   └── main.dart          # Interface Flutter
├── server.dart            # API REST em Dart
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── res/xml/
│           └── network_security_config.xml
├── pubspec.yaml
└── README.md
```

---

## API REST

| Método | Rota             | Descrição            |
|--------|------------------|----------------------|
| GET    | /usuarios        | Lista todos          |
| POST   | /usuarios        | Cadastra novo        |
| PUT    | /usuarios/:id    | Atualiza existente   |
| DELETE | /usuarios/:id    | Remove               |

---

## Autor

Desenvolvido por **ticishinmi**
