import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cadastro de Usuários',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const UserListPage(),
    );
  }
}

class User {
  int? id;
  String name;
  int age;
  String gender;

  User({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['nome'],
        age: json['idade'],
        gender: json['sexo'],
      );

  Map<String, dynamic> toJson() => {
        'nome': name,
        'idade': age,
        'sexo': gender,
      };
}

// ---------------------------------------------------------------------------
// Popup do Sexo
// ---------------------------------------------------------------------------

class _GenderPopup extends StatefulWidget {
  final List<String> genders;
  final String? selectedItem;
  final void Function(String) onSelect;
  final Widget child;

  const _GenderPopup({
    required this.genders,
    required this.selectedItem,
    required this.onSelect,
    required this.child,
  });

  @override
  State<_GenderPopup> createState() => _GenderPopupState();
}

class _GenderPopupState extends State<_GenderPopup> {
  late int _highlighted;
  final _scrollController = ScrollController();
  static const _itemHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _highlighted = widget.selectedItem != null
        ? widget.genders.indexOf(widget.selectedItem!)
        : -1;
  }

  void _moveTo(int idx) {
    if (idx < 0 || idx >= widget.genders.length) return;
    setState(() => _highlighted = idx);
    _scrollController.animateTo(
      idx * _itemHeight,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_highlighted >= 0 && _highlighted < widget.genders.length) {
        widget.onSelect(widget.genders[_highlighted]);
      }
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveTo(_highlighted < widget.genders.length - 1 ? _highlighted + 1 : 0);
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveTo(_highlighted > 0 ? _highlighted - 1 : widget.genders.length - 1);
      return;
    }

    final char = event.character;
    if (char == null || char.isEmpty) return;
    final idx = widget.genders.indexWhere(
      (e) => e.toLowerCase().startsWith(char.toLowerCase()),
    );
    if (idx != -1) _moveTo(idx);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _onKey,
      child: _GenderPopupScope(
        highlighted: _highlighted,
        scrollController: _scrollController,
        genders: widget.genders,
        onSelect: widget.onSelect,
        child: widget.child,
      ),
    );
  }
}

class _GenderPopupScope extends InheritedWidget {
  final int highlighted;
  final ScrollController scrollController;
  final List<String> genders;
  final void Function(String) onSelect;

  const _GenderPopupScope({
    required this.highlighted,
    required this.scrollController,
    required this.genders,
    required this.onSelect,
    required super.child,
  });

  static _GenderPopupScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GenderPopupScope>();

  @override
  bool updateShouldNotify(_GenderPopupScope old) =>
      highlighted != old.highlighted;
}

class _GenderItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _GenderItem({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final scope = _GenderPopupScope.of(context);
    final index = scope?.genders.indexOf(label) ?? -1;
    final isHighlighted = scope?.highlighted == index;

    Color? bg;
    if (isSelected) {
      bg = Theme.of(context).colorScheme.primaryContainer;
    } else if (isHighlighted) {
      bg = Theme.of(context).colorScheme.secondaryContainer;
    }

    return Container(
      height: 48,
      color: bg,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected || isHighlighted
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de usuários
// ---------------------------------------------------------------------------

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  // localhost no emulador Android = 10.0.2.2
  // Troque por localhost ao rodar no Chrome
  static const _apiUrl = 'http://10.0.2.2:8080/usuarios';

  final List<User> users = [];
  final _searchController = TextEditingController();
  String _searchText = '';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
    });
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse(_apiUrl));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          users
            ..clear()
            ..addAll(data.map((e) => User.fromJson(e)));
        });
      } else {
        setState(() => _error = 'Erro ao carregar usuários.');
      }
    } catch (e) {
      setState(() => _error = 'Sem conexão com o servidor.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm({User? user}) async {
    final result = await Navigator.push<User>(
      context,
      MaterialPageRoute(builder: (_) => UserFormPage(user: user)),
    );

    if (result != null) {
      setState(() { _loading = true; _error = null; });
      try {
        http.Response res;
        if (result.id == null) {
          res = await http.post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(result.toJson()),
          );
        } else {
          res = await http.put(
            Uri.parse('$_apiUrl/${result.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(result.toJson()),
          );
        }
        if (res.statusCode == 200 || res.statusCode == 201) {
          _searchController.clear();
          await _fetchUsers();
        } else {
          setState(() => _error = 'Erro ao salvar usuário.');
        }
      } catch (e) {
        setState(() => _error = 'Sem conexão com o servidor.');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir o usuário "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() { _loading = true; _error = null; });
      try {
        final res = await http.delete(Uri.parse('$_apiUrl/${user.id}'));
        if (res.statusCode == 200) {
          _searchController.clear();
          await _fetchUsers();
        } else {
          setState(() => _error = 'Erro ao excluir usuário.');
        }
      } catch (e) {
        setState(() => _error = 'Sem conexão com o servidor.');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lista de Usuários'),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filtrar...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _fetchUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          final filtered = users
              .where((u) => u.name.toLowerCase().contains(_searchText))
              .toList();
          if (users.isEmpty) {
            return const Center(child: Text('Nenhum usuário cadastrado'));
          }
          if (filtered.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado'));
          }
          return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final user = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.name),
                    subtitle:
                        Text('Idade: ${user.age} | Sexo: ${user.gender}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blue),
                          tooltip: 'Editar usuário',
                          onPressed: () => _openForm(user: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Excluir usuário',
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
        },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulário de usuário
// ---------------------------------------------------------------------------

class UserFormPage extends StatefulWidget {
  final User? user;

  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController ageController;

  late FocusNode nameFocusNode;
  late FocusNode ageFocusNode;
  late FocusNode genderFocusNode;
  late FocusNode saveFocusNode;

  final _dropdownKey = GlobalKey<DropdownSearchState<String>>();

  String? gender;

  final List<String> genders = ['Masculino', 'Feminino', 'Outro'];

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.user?.name ?? '');
    ageController =
        TextEditingController(text: widget.user?.age.toString() ?? '');
    gender = widget.user?.gender;

    nameFocusNode = FocusNode();
    ageFocusNode = FocusNode();
    genderFocusNode = FocusNode();
    saveFocusNode = FocusNode();

    genderFocusNode.addListener(() {
      if (genderFocusNode.hasFocus) {
        Future.delayed(Duration.zero, () {
          _dropdownKey.currentState?.openDropDownSearch();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    nameFocusNode.dispose();
    ageFocusNode.dispose();
    genderFocusNode.dispose();
    saveFocusNode.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String label, {bool focused = false}) {
    return InputDecoration(
      labelText: label,
      filled: focused,
      fillColor: focused ? Colors.blue.shade50 : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _selectGender(String value) {
    setState(() => gender = value);
    _dropdownKey.currentState?.changeSelectedItem(value);
    final nav = Navigator.of(context, rootNavigator: false);
    if (nav.canPop()) nav.pop();
    Future.delayed(Duration.zero, () {
      saveFocusNode.requestFocus();
    });
  }

  void _save() {
    // Valida e coloca foco no primeiro campo inválido
    if (!_formKey.currentState!.validate()) {
      if (nameController.text.trim().isEmpty) {
        nameFocusNode.requestFocus();
      } else if (ageController.text.isEmpty || int.tryParse(ageController.text) == null) {
        ageFocusNode.requestFocus();
      } else if (gender == null || gender!.isEmpty) {
        genderFocusNode.requestFocus();
      }
      return;
    }
    Navigator.pop(
      context,
      User(
        id: widget.user?.id,
        name: nameController.text.trim(),
        age: int.parse(ageController.text),
        gender: gender!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.user == null ? 'Novo Usuário' : 'Editar Usuário'),
      ),
      body: Center(
        child: Container(
          width: width * 0.5,
          constraints:
              const BoxConstraints(minWidth: 320, maxWidth: 600),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Formulário de Usuário',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 24),

                    ListenableBuilder(
                      listenable: nameFocusNode,
                      builder: (context, _) => TextFormField(
                        controller: nameController,
                        focusNode: nameFocusNode,
                        decoration: fieldDecoration('Nome', focused: nameFocusNode.hasFocus),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(ageFocusNode),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nome é obrigatório'
                            : null,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ListenableBuilder(
                      listenable: ageFocusNode,
                      builder: (context, _) => TextFormField(
                        controller: ageController,
                        focusNode: ageFocusNode,
                        decoration: fieldDecoration('Idade', focused: ageFocusNode.hasFocus),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(genderFocusNode),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Idade é obrigatória';
                          if (int.tryParse(v) == null) return 'Digite apenas números';
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    ListenableBuilder(
                      listenable: genderFocusNode,
                      builder: (context, _) => Focus(
                        focusNode: genderFocusNode,
                        skipTraversal: true,
                        child: DropdownSearch<String>(
                          key: _dropdownKey,
                          items: (_, __) => genders,
                          selectedItem: gender,
                          decoratorProps: DropDownDecoratorProps(
                            decoration: fieldDecoration('Sexo', focused: genderFocusNode.hasFocus),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: false,
                            constraints: const BoxConstraints(maxHeight: 144),
                            itemBuilder: (ctx, item, isDisabled, isSelected) =>
                                _GenderItem(label: item, isSelected: isSelected),
                            containerBuilder: (ctx, popupWidget) => _GenderPopup(
                              genders: genders,
                              selectedItem: gender,
                              onSelect: _selectGender,
                              child: popupWidget,
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Sexo é obrigatório'
                              : null,
                          onChanged: (v) => setState(() => gender = v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    ListenableBuilder(
                      listenable: saveFocusNode,
                      builder: (context, _) => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          focusNode: saveFocusNode,
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: saveFocusNode.hasFocus ? Colors.green : null,
                            foregroundColor: saveFocusNode.hasFocus ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
