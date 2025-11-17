import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

/// ---- CONFIG ----
const String baseUrl =
    'http://localhost:8080'; 

/// ---- MODEL ----

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
    id: json['id']?.toString() ?? '',
    title: json['title'] ?? json['Title'] ?? '',
    description: json['desc'] ?? json['Description'] ?? '',
    dueDate: json['dueDate'] != null && json['dueDate'] != ''
        ? DateTime.tryParse(json['dueDate'])
        : (json['DueDate'] != null && json['DueDate'] != ''
            ? DateTime.tryParse(json['DueDate'])
            : null),
    createdTime: json['createdTime'] != null && json['createdTime'] != ''
        ? DateTime.tryParse(json['createdTime'])
        : (json['CreatedTime'] != null && json['CreatedTime'] != ''
            ? DateTime.tryParse(json['CreatedTime'])
            : null),
    isCompleted:
        (json['isCompleted'] ?? json['IsCompleted'] ?? false) as bool,
    completedTime:
        json['completedTime'] != null && json['completedTime'] != ''
            ? DateTime.tryParse(json['completedTime'])
            : (json['CompletedTime'] != null && json['CompletedTime'] != ''
                ? DateTime.tryParse(json['CompletedTime'])
                : null),
  );
}

  /// Create için: TodoCreate struct'a uygun body
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'desc': description,
      if (dueDate != null) 'dueDate': dueDate!.toUtc().toIso8601String(),
    };
  }

  /// Update için: TodoUpdate struct'a uygun body
  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'desc': description,
      if (dueDate != null) 'dueDate': dueDate!.toUtc().toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}

/// ---- API SERVİS ----

class TodoApi {
  Future<List<Todo>> fetchTodos() async {
    final uri = Uri.parse('$baseUrl/todo');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('ToDo listesi alınamadı: ${response.statusCode}');
    }
  }

  Future<Todo> createTodo(Todo todo) async {
    final uri = Uri.parse('$baseUrl/todo');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(todo.toCreateJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Todo.fromJson(data);
    } else {
      throw Exception('ToDo oluşturulamadı: ${response.body}');
    }
  }

  Future<Todo> updateTodo(Todo todo) async {
    final uri = Uri.parse('$baseUrl/todo/${todo.id}');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(todo.toUpdateJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Todo.fromJson(data);
    } else {
      throw Exception('ToDo güncellenemedi: ${response.body}');
    }
  }

  Future<void> deleteTodo(String id) async {
    final uri = Uri.parse('$baseUrl/todo/$id');
    final response = await http.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('ToDo silinemedi: ${response.body}');
    }
  }
}

/// ---- UI ----

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go ToDo + Flutter',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TodoApi _api = TodoApi();

  late Future<List<Todo>> _todosFuture;
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _todosFuture = _api.fetchTodos();
    });
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }

  Future<void> _openCreateOrEditDialog({Todo? todo}) async {
    final isEdit = todo != null;

    final titleController =
        TextEditingController(text: isEdit ? todo!.title : '');
    final descController =
        TextEditingController(text: isEdit ? todo!.description : '');
    DateTime? selectedDueDate = isEdit ? todo!.dueDate : null;
    bool isCompleted = isEdit ? todo!.isCompleted : false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: Text(isEdit ? 'ToDo Güncelle' : 'Yeni ToDo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                        hintText: 'En fazla 50 karakter',
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        hintText: '3-200 karakter arası',
                      ),
                      maxLength: 200,
                      minLines: 2,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate != null
                                ? 'Bitiş: ${_dateFormat.format(selectedDueDate!)}'
                                : 'Bitiş tarihi seçilmedi',
                          ),
                        ),
                        TextButton(
  onPressed: () async {
    final now = DateTime.now();

    // Picker için güvenli başlangıç tarihi
    final initial = (selectedDueDate != null && selectedDueDate!.year > 1)
        ? selectedDueDate!
        : now;

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: initial,
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      final result = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );

      setInnerState(() {
        selectedDueDate = result;
      });
    }
  },
  child: const Text('Tarih seç'),
),

                      ],
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Tamamlandı'),
                        value: isCompleted,
                        onChanged: (val) {
                          setInnerState(() {
                            isCompleted = val;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();

                    if (title.isEmpty || desc.length < 3) {
                      _showError(
                        context,
                        'Validasyon: title zorunlu, desc min 3 karakter.',
                      );
                      return;
                    }

                    try {
                      if (isEdit) {
                        todo!
                          ..title = title
                          ..description = desc
                          ..dueDate = selectedDueDate
                          ..isCompleted = isCompleted;

                        await _api.updateTodo(todo);
                      } else {
                        final newTodo = Todo(
                          id: '', // backend ID’yi create sonrası atayacak
                          title: title,
                          description: desc,
                          dueDate: selectedDueDate,
                          isCompleted: false,
                        );
                        await _api.createTodo(newTodo);
                      }

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        _reload();
                      }
                    } catch (e) {
                      _showError(context, e);
                    }
                  },
                  child: Text(isEdit ? 'Güncelle' : 'Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleCompleted(Todo todo) async {
    try {
      todo.isCompleted = !todo.isCompleted;
      await _api.updateTodo(todo);
      _reload();
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    try {
      await _api.deleteTodo(todo.id);
      _reload();
    } catch (e) {
      _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo (Go + Flutter)'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Todo>>(
        future: _todosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }
          final todos = snapshot.data ?? [];
          if (todos.isEmpty) {
            return const Center(
              child: Text('Henüz hiç ToDo yok. + ile ekleyebilirsin.'),
            );
          }
          return ListView.separated(
            itemCount: todos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                leading: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => _toggleCompleted(todo),
                ),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (todo.description.isNotEmpty)
                      Text(todo.description),
                    if (todo.dueDate != null && todo.dueDate!.year > 1)
                      Text('Bitiş: ${_dateFormat.format(todo.dueDate!)}'),
                    if (todo.createdTime != null)
                      Text(
                        'Oluşturma: ${_dateFormat.format(todo.createdTime!)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                ),
                onTap: () => _openCreateOrEditDialog(todo: todo),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTodo(todo),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateOrEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
