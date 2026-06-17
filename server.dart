import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

// ---------------------------------------------------------------------------
// Configuração do banco
// ---------------------------------------------------------------------------
Future<Connection> openConnection() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'banco',
      username: 'postgres',
      password: 'admin',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
  return conn;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Response jsonResponse(Object data, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(data),
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  );
}

Response errorResponse(String message, {int status = 500}) {
  return jsonResponse({'error': message}, status: status);
}

// Middleware para liberar CORS (preflight OPTIONS)
Middleware corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        });
      }
      final response = await handler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      });
    };
  };
}

// ---------------------------------------------------------------------------
// Rotas
// ---------------------------------------------------------------------------

// GET /usuarios — lista todos
Future<Response> getUsuarios(Request req) async {
  try {
    final conn = await openConnection();
    final result = await conn.execute(
      'SELECT id, nome, idade, sexo FROM usuarios ORDER BY nome',
    );
    await conn.close();
    final users = result.map((row) => {
      'id': row[0],
      'nome': row[1],
      'idade': row[2],
      'sexo': row[3],
    }).toList();
    return jsonResponse(users);
  } catch (e) {
    return errorResponse(e.toString());
  }
}

// POST /usuarios — cadastra novo
Future<Response> postUsuario(Request req) async {
  try {
    final body = jsonDecode(await req.readAsString());
    final conn = await openConnection();
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO usuarios (nome, idade, sexo) VALUES (@nome, @idade, @sexo) RETURNING id',
      ),
      parameters: {
        'nome': body['nome'],
        'idade': body['idade'],
        'sexo': body['sexo'],
      },
    );
    await conn.close();
    final id = result.first[0];
    return jsonResponse({'id': id, ...body}, status: 201);
  } catch (e) {
    return errorResponse(e.toString());
  }
}

// PUT /usuarios/:id — atualiza
Future<Response> putUsuario(Request req, String id) async {
  try {
    final body = jsonDecode(await req.readAsString());
    final conn = await openConnection();
    await conn.execute(
      Sql.named(
        'UPDATE usuarios SET nome=@nome, idade=@idade, sexo=@sexo WHERE id=@id',
      ),
      parameters: {
        'nome': body['nome'],
        'idade': body['idade'],
        'sexo': body['sexo'],
        'id': int.parse(id),
      },
    );
    await conn.close();
    return jsonResponse({'id': int.parse(id), ...body});
  } catch (e) {
    return errorResponse(e.toString());
  }
}

// DELETE /usuarios/:id — exclui
Future<Response> deleteUsuario(Request req, String id) async {
  try {
    final conn = await openConnection();
    await conn.execute(
      Sql.named('DELETE FROM usuarios WHERE id=@id'),
      parameters: {'id': int.parse(id)},
    );
    await conn.close();
    return jsonResponse({'deleted': int.parse(id)});
  } catch (e) {
    return errorResponse(e.toString());
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
void main() async {
  // Cria a tabela se não existir
  try {
    final conn = await openConnection();
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id    SERIAL PRIMARY KEY,
        nome  VARCHAR(100) NOT NULL,
        idade INTEGER      NOT NULL,
        sexo  VARCHAR(20)  NOT NULL
      )
    ''');
    await conn.close();
    print('Tabela "usuarios" verificada/criada com sucesso.');
  } catch (e) {
    print('Erro ao conectar ao banco: $e');
    exit(1);
  }

  final router = Router()
    ..get('/usuarios', getUsuarios)
    ..post('/usuarios', postUsuario)
    ..put('/usuarios/<id>', putUsuario)
    ..delete('/usuarios/<id>', deleteUsuario);

  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Servidor rodando em http://${server.address.host}:${server.port}');
}
