import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  static Future<void> toggleTask(String taskId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.patch(
    Uri.parse('$baseUrl/tasks/$taskId/toggle'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to toggle task');
  }
}
  static Future<void> createProject(
  String name,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.post(
    Uri.parse('$baseUrl/projects'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'name': name,
    }),
  );

  if (response.statusCode != 201 &&
      response.statusCode != 200) {
    throw Exception('Failed to create project');
  }
}

  static Future<Map<String, dynamic>>
    getTaskStats(
  String projectId,
) async {
  final prefs =
      await SharedPreferences.getInstance();

  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse(
      '$baseUrl/tasks/project/$projectId/stats',
    ),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception(
    'Failed to load stats',
  );
}


  static Future<void> deleteTask(String taskId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.delete(
    Uri.parse('$baseUrl/tasks/$taskId'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200 &&
      response.statusCode != 204) {
    throw Exception('Failed to delete task');
  }
}
  static Future<void> deleteProject(
    String projectId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/projects/$projectId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception('Failed to delete project');
    }
  }
  static Future<List<dynamic>> getProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/projects'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load projects');
  }

  static Future<List<dynamic>> getTasks(
    String projectId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(
        '$baseUrl/tasks/project/$projectId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load tasks');
  }
  static Future<void> createTask(
  String projectId,
  String title,
  String description,
  DateTime? dueDate,
  String priority,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.post(
    Uri.parse(
      '$baseUrl/tasks/project/$projectId',
    ),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
    }),
  );

  if (response.statusCode != 201 &&
      response.statusCode != 200) {
    throw Exception('Failed to create task');
  }
}

 static Future<void> updateTask(
  String taskId,
  String title,
  String description,
  DateTime? dueDate,
  String priority,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.patch(
    Uri.parse('$baseUrl/tasks/$taskId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update task');
  }
} 
}