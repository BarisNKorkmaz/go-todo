// Tamamen çalışır hale getirilmiş FULL main.dart dosyası

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginRegisterPage(),
    );
  }
}

// =============================
// CONFIG
// =============================
const String baseUrl = 'http://localhost:8080';

// =============================
// AUTH SERVICE (TOKEN)
// =============================
class AuthService {
  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

// =============================
// TODO MODEL
// =============================
class Todo {
  final String id;
  String title;
  String description;
  DateTime? dueDate;
  DateTime? createdTime;
  bool isCompleted;
  DateTime? completedTime;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.createdTime,
    this.isCompleted = false,
    this.completedTime,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
  return Todo(
    id: json['id'].toString(),
    title: json['title'] ?? '',
    description: json['desc'] ?? '',
    dueDate: (json['dueDate'] != null &&
          json['dueDate'] != "" &&
          json['dueDate'] != "0001-01-01T00:00:00Z")
        ? DateTime.tryParse(json['dueDate'])
        : null,
    createdTime: json['createdTime'] != null ? DateTime.tryParse(json['createdTime']) : null,
    isCompleted: json['isCompleted'] != null &&
        json['isCompleted'].toString().toLowerCase() == "true",
    completedTime: json['completedTime'] != null
        ? DateTime.tryParse(json['completedTime'])
        : null,
  );
}

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'desc': description,
      if (dueDate != null) 'dueDate': dueDate!.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'desc': description,
      if (dueDate != null) 'dueDate': dueDate!.toUtc().toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}

// =============================
// API SERVICE
// =============================
class TodoApi {
  final AuthService _auth = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.loadToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Todo>> fetchTodos() async {
    final uri = Uri.parse('$baseUrl/todo');
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Todo.fromJson(e)).toList();
    }
    throw Exception('ToDo listesi alınamadı: ${response.body}');
  }

  Future<Todo> create(Todo todo) async {
    final uri = Uri.parse('$baseUrl/todo');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(todo.toCreateJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Todo.fromJson(jsonDecode(response.body));
    }
    throw Exception('Oluşturulamadı: ${response.body}');
  }

  Future<Todo> update(Todo todo) async {
    final uri = Uri.parse('$baseUrl/todo/${todo.id}');
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(todo.toUpdateJson()),
    );

    if (response.statusCode == 200) {
      return Todo.fromJson(jsonDecode(response.body));
    }
    throw Exception('Güncellenemedi: ${response.body}');
  }

  Future<void> delete(String id) async {
    final uri = Uri.parse('$baseUrl/todo/$id');
    final response = await http.delete(uri, headers: await _headers());

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Silinemedi: ${response.body}');
    }
  }

  Future<void> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _auth.saveToken(data['token']);
      return;
    }
    throw Exception(response.body);
  }

  Future<void> register(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

  Future<void> logout() async => _auth.clearToken();
}

// =============================
// LOGIN / REGISTER SCREEN
// =============================
class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  final api = TodoApi();

  final loginEmail = TextEditingController();
  final loginPass = TextEditingController();

  final regEmail = TextEditingController();
  final regPass = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this);
  }

  void showErr(e) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş / Kayıt'),
        bottom: TabBar(
          controller: controller,
          tabs: const [Tab(text: "Giriş"), Tab(text: "Kayıt")],
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: [_buildLogin(), _buildRegister()],
      ),
    );
  }

  Widget _buildLogin() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        TextField(controller: loginEmail, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: loginPass, decoration: const InputDecoration(labelText: 'Şifre'), obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              await api.login(loginEmail.text, loginPass.text);
              if (mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const TodoPage()));
              }
            } catch (e) {
              showErr(e);
            }
          },
          child: const Text('Giriş Yap'),
        ),
      ]),
    );
  }

  Widget _buildRegister() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        TextField(controller: regEmail, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: regPass, decoration: const InputDecoration(labelText: 'Şifre'), obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              await api.register(regEmail.text, regPass.text);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Kayıt başarılı! Giriş yap.')));
              controller.animateTo(0);
            } catch (e) {
              showErr(e);
            }
          },
          child: const Text('Kayıt Ol'),
        ),
      ]),
    );
  }
}

// =============================
// TODO PAGE (FULL IMPLEMENTATION)
// =============================
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TodoApi _api = TodoApi();
  late Future<List<Todo>> _futureTodos;

  final DateFormat _fmt = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _futureTodos = _api.fetchTodos();
    });
  }

  void _showErr(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> _openCreateOrEdit({Todo? todo}) async {
    final isEdit = todo != null;

    final titleC = TextEditingController(text: todo?.title ?? '');
    final descC = TextEditingController(text: todo?.description ?? '');
    DateTime? dueDate = todo?.dueDate;
    bool isCompleted = todo?.isCompleted ?? false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setInner) {
          return AlertDialog(
            title: Text(isEdit ? "ToDo Güncelle" : "Yeni ToDo"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleC,
                    decoration: const InputDecoration(labelText: "Başlık"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descC,
                    decoration: const InputDecoration(labelText: "Açıklama"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dueDate != null
                              ? "Son Tarih: ${_fmt.format(dueDate!)}"
                              : "Tarih seçilmedi",
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final init = dueDate ?? now;

                          final date = await showDatePicker(
                            context: context,
                            initialDate: init,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );

                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(init),
                            );

                            final chosen = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? 0,
                              time?.minute ?? 0,
                            );

                            setInner(() => dueDate = chosen);
                          }
                        },
                        child: const Text("Tarih Seç"),
                      )
                    ],
                  ),
                  if (isEdit)
                    SwitchListTile(
                      title: const Text("Tamamlandı"),
                      value: isCompleted,
                      onChanged: (v) => setInner(() => isCompleted = v),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              ElevatedButton(
  onPressed: () async {
    try {
      if (isEdit) {
        todo!.title = titleC.text;
        todo.description = descC.text;
        todo.dueDate = dueDate;
        todo.isCompleted = isCompleted;

        await _api.update(todo);
      } else {
        final newTodo = Todo(
          id: '',
          title: titleC.text,
          description: descC.text,
          dueDate: dueDate,
        );
        await _api.create(newTodo);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      _reload(); // 🔥 Güncellemeden SONRA listeyi yenile
    } catch (e) {
      _showErr(e);
    }
  },
  child: Text(isEdit ? "Güncelle" : "Oluştur"),
)

            ],
          );
        });
      },
    );
  }

  Future<void> _delete(Todo todo) async {
    try {
      await _api.delete(todo.id);
      _reload();
    } catch (e) {
      _showErr(e);
    }
  }

  Future<void> _toggle(Todo todo) async {
    try {
      todo.isCompleted = !todo.isCompleted;
      await _api.update(todo);
      _reload();
    } catch (e) {
      _showErr(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ToDo Listesi"),
        actions: [
          IconButton(
              onPressed: () async {
                await TodoApi().logout();
                if (mounted) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginRegisterPage()));
                }
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateOrEdit(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Todo>>(
        future: _futureTodos,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text("Hata: ${snap.error}"));
          }

          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text("Henüz hiç ToDo yok"));
          }

          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = list[i];
              return ListTile(
                leading: Checkbox(
                  value: t.isCompleted,
                  onChanged: (_) => _toggle(t),
                ),
                title: Text(
                  t.title,
                  style: TextStyle(
                    decoration: t.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (t.description.isNotEmpty) Text(t.description),
                    if (t.dueDate != null)
                      Text("Bitiş: ${_fmt.format(t.dueDate!)}"),
                    if (t.createdTime != null)
                      Text("Oluşturma: ${_fmt.format(t.createdTime!)}",
                          style: const TextStyle(fontSize: 11)),
                  ],
                ),
                onTap: () => _openCreateOrEdit(todo: t),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(t),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
