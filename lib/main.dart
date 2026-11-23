import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const Aula10CrudRestApp());
}

class Aula10CrudRestApp extends StatelessWidget {
  const Aula10CrudRestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aula 10 - API REST (POST, PUT, DELETE)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PostsCrudScreen(),
    );
  }
}

class PostModel {
  final int id;
  final int userId;
  final String title;
  final String body;

  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
    };
  }
}

class PostsCrudScreen extends StatefulWidget {
  const PostsCrudScreen({super.key});

  @override
  State<PostsCrudScreen> createState() => _PostsCrudScreenState();
}

class _PostsCrudScreenState extends State<PostsCrudScreen> {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com/posts';

  final TextEditingController _buscaController = TextEditingController();
  List<PostModel> _posts = [];
  bool _carregando = true;
  bool _pesquisando = false;

  @override
  void initState() {
    super.initState();
    _carregarPosts(mostrarSnack: false);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // Exercicio 03: Exibe o statusCode retornado pelo servidor na SnackBar
  void _exibirStatusSnackBar({
    required String metodo,
    required int statusCode,
    required String mensagem,
    Color cor = Colors.deepPurple,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('[$metodo | HTTP $statusCode] $mensagem'),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // GET: Busca lista inicial de posts
  Future<void> _carregarPosts({bool mostrarSnack = true}) async {
    setState(() => _carregando = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl?_limit=15'));
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _posts = decoded
              .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
              .toList();
        });
        if (mostrarSnack) {
          _exibirStatusSnackBar(
            metodo: 'GET',
            statusCode: response.statusCode,
            mensagem: '${_posts.length} posts carregados com sucesso.',
            cor: Colors.teal,
          );
        }
      } else {
        _exibirStatusSnackBar(
          metodo: 'GET',
          statusCode: response.statusCode,
          mensagem: 'Falha ao carregar posts.',
          cor: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // POST: Cria um novo post no servidor
  Future<void> _criarPost(String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final novoPost = PostModel(
          id: (data['id'] as num?)?.toInt() ?? (_posts.length + 101),
          userId: 1,
          title: title,
          body: body,
        );
        setState(() {
          _posts.insert(0, novoPost);
        });
        _exibirStatusSnackBar(
          metodo: 'POST',
          statusCode: response.statusCode,
          mensagem: 'Post "${novoPost.title}" criado com sucesso!',
          cor: Colors.green.shade700,
        );
      } else {
        _exibirStatusSnackBar(
          metodo: 'POST',
          statusCode: response.statusCode,
          mensagem: 'Erro ao criar post.',
          cor: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro POST: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // PUT: Atualiza um post existente
  Future<void> _atualizarPost(PostModel post, String novoTitle, String novoBody) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${post.id}'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'id': post.id,
          'title': novoTitle,
          'body': novoBody,
          'userId': post.userId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = PostModel(
              id: post.id,
              userId: post.userId,
              title: novoTitle,
              body: novoBody,
            );
          }
        });
        _exibirStatusSnackBar(
          metodo: 'PUT',
          statusCode: response.statusCode,
          mensagem: 'Post #${post.id} atualizado com sucesso!',
          cor: Colors.blue.shade700,
        );
      } else {
        _exibirStatusSnackBar(
          metodo: 'PUT',
          statusCode: response.statusCode,
          mensagem: 'Erro ao atualizar post #${post.id}.',
          cor: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro PUT: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Exercicio 01: AlertDialog de confirmacao visual antes de disparar DELETE
  Future<void> _confirmarEDeletarPost(PostModel post) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
          title: const Text('Confirmar Exclusão (DELETE)'),
          content: Text(
            'Tem certeza que deseja excluir permanentemente o post #${post.id}:\n\n"${post.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Confirmar DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmado == true) {
      await _deletarPost(post);
    }
  }

  // DELETE: Remove o post no servidor apos confirmacao
  Future<void> _deletarPost(PostModel post) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/${post.id}'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
        });
        _exibirStatusSnackBar(
          metodo: 'DELETE',
          statusCode: response.statusCode,
          mensagem: 'Post #${post.id} excluído do servidor!',
          cor: Colors.orange.shade800,
        );
      } else {
        _exibirStatusSnackBar(
          metodo: 'DELETE',
          statusCode: response.statusCode,
          mensagem: 'Falha ao excluir post #${post.id}.',
          cor: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro DELETE: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _abrirFormularioPost({PostModel? postParaEditar}) {
    final titleController = TextEditingController(text: postParaEditar?.title ?? '');
    final bodyController = TextEditingController(text: postParaEditar?.body ?? '');
    final isEdicao = postParaEditar != null;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEdicao ? 'Editar Post (PUT)' : 'Novo Post (POST)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título do Post',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo / Corpo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                if (title.isEmpty) return;
                Navigator.of(dialogContext).pop();
                if (isEdicao) {
                  _atualizarPost(
                    postParaEditar,
                    title,
                    body.isEmpty ? 'Conteúdo atualizado via PUT' : body,
                  );
                } else {
                  _criarPost(
                    title,
                    body.isEmpty ? 'Novo post enviado via POST' : body,
                  );
                }
              },
              child: Text(isEdicao ? 'Salvar (PUT)' : 'Enviar (POST)'),
            ),
          ],
        );
      },
    );
  }

  // Exercicio 02: Filtra posts localmente pelo titulo digitado na AppBar
  List<PostModel> get _postsFiltrados {
    final termo = _buscaController.text.trim().toLowerCase();
    if (termo.isEmpty) return _posts;
    return _posts
        .where((post) => post.title.toLowerCase().contains(termo))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final listaExibida = _postsFiltrados;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        // Exercicio 02: TextField na AppBar para pesquisar posts pelo titulo
        title: _pesquisando
            ? TextField(
                controller: _buscaController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Pesquisar posts pelo título...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('CRUD API REST - Aula 10'),
        actions: [
          IconButton(
            tooltip: _pesquisando ? 'Fechar busca' : 'Filtrar posts por título',
            icon: Icon(_pesquisando ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_pesquisando) {
                  _buscaController.clear();
                }
                _pesquisando = !_pesquisando;
              });
            },
          ),
          IconButton(
            tooltip: 'Recarregar (GET)',
            icon: const Icon(Icons.refresh),
            onPressed: () => _carregarPosts(mostrarSnack: true),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : listaExibida.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum post encontrado para o filtro informado.',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: listaExibida.length,
                  itemBuilder: (context, index) {
                    final post = listaExibida[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Text(
                            '#${post.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        title: Text(
                          post.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            post.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar (PUT)',
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _abrirFormularioPost(postParaEditar: post),
                            ),
                            IconButton(
                              tooltip: 'Excluir (DELETE)',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmarEDeletarPost(post),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioPost(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Post (POST)'),
      ),
    );
  }
}
