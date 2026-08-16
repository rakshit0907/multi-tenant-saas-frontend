import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
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

 static Future<String> getMyProjectRole(
  String projectId,
 ) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final response = await http.get(
    Uri.parse(
      '$baseUrl/projects/$projectId/my-role',
    ),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["role"];
  }

  throw Exception("Failed to load role");
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

    debugPrint("DELETE STATUS: ${response.statusCode}");
    debugPrint("DELETE BODY: ${response.body}");

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

  static Future<List<UserModel>> getOrganizationUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/tenant/users'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((e) => UserModel.fromJson(e))
          .toList();
    }

    throw Exception("Failed to load organization users");
  }

  static Future<List<dynamic>> getProjectMembers(
    String projectId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/projects/$projectId/members'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint("STATUS: ${response.statusCode}");
    debugPrint("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }  

    throw Exception('Failed to load members');
  }

  static Future<void> removeProjectMember(
    String projectId,
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse(
        '$baseUrl/projects/$projectId/members/$userId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint("REMOVE MEMBER STATUS: ${response.statusCode}");
    debugPrint("REMOVE MEMBER BODY: ${response.body}");
    
    if (response.statusCode != 200 &&
       response.statusCode != 204) {
        throw Exception(
          'Failed to remove member',
        );
     }
  } 

  static Future<void> addMember(
    String projectId,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
     );

     if (response.statusCode != 200 &&
         response.statusCode != 201) {

       debugPrint("Invite Member STATUS: ${response.statusCode}");
       debugPrint("Invite Member BODY: ${response.body}");

       throw Exception('Failed to add member');
}
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

  static Future<Map<String, dynamic>> getTask(
    String taskId,

  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load task');
  }
  static Future<void> createTask(
  String projectId,
  String title,
  String description,
  DateTime? dueDate,
  String priority,
  String status,
  String? assigneeId,
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
      'status': status,
      'assigneeId': assigneeId,
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
  String status,
  String? assigneeId,
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
      'status': status,
      'assigneeId': assigneeId,
    }),
  );

  if (response.statusCode !=200) {
    throw Exception('Failed to update task');
  }
}

  static Future<void> updateTaskStatus(
    String taskId,
    String status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );
 
  if (response.statusCode != 200) {
    throw Exception('Failed to update task status');
  }
  }

  static Future<void> createInvitation(
    String projectId,
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse(
        '$baseUrl/project-invitations/projects/$projectId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
      }),
    );

    debugPrint("CREATE INVITATION STATUS: ${response.statusCode}");
    debugPrint("CREATE INVITATION BODY: ${response.body}");

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception('Failed to create invitation');
    }
  }

 static Future<List<dynamic>> getMyInvitations() async {
   final prefs = await SharedPreferences.getInstance();
   final token = prefs.getString('token');

   final response = await http.get(
     Uri.parse('$baseUrl/project-invitations/mine'),
     headers: {
       'Authorization': 'Bearer $token',
     },
   );

   debugPrint("MY INVITATIONS STATUS: ${response.statusCode}");
   debugPrint("MY INVITATIONS BODY: ${response.body}");

   if (response.statusCode == 200) {
     return jsonDecode(response.body);
   }

   throw Exception('Failed to load invitations');
 }

 static Future<void> acceptInvitation(
   String invitationId,
 ) async {
   final prefs = await SharedPreferences.getInstance();
   final token = prefs.getString('token');

   final response = await http.patch(
     Uri.parse(
       '$baseUrl/project-invitations/$invitationId/accept',
     ),
     headers: {
      'Authorization': 'Bearer $token',
     },
   );

   debugPrint("ACCEPT INVITATION STATUS: ${response.statusCode}");
   debugPrint("ACCEPT INVITATION BODY: ${response.body}");

   if (response.statusCode != 200) {
     throw Exception('Failed to accept invitation');
   }
 }

 static Future<void> rejectInvitation(
   String invitationId,
 ) async {
   final prefs = await SharedPreferences.getInstance();
   final token = prefs.getString('token');

   final response = await http.patch(
     Uri.parse(
       '$baseUrl/project-invitations/$invitationId/reject',
     ),
     headers: {
       'Authorization': 'Bearer $token',
     },
   );

   debugPrint("REJECT INVITATION STATUS: ${response.statusCode}");
   debugPrint("REJECT INVITATION BODY: ${response.body}");

   if (response.statusCode != 200) {
     throw Exception('Failed to reject invitation');
   }
  }
  
  static Future<List<dynamic>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint("NOTIFICATIONS STATUS: ${response.statusCode}");
    debugPrint("NOTIFICATIONS BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load notifications');
  }

  static Future<int> getUnreadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    }

    throw Exception('Failed to load unread notification count');
  }

  static Future<void> markNotificationAsRead(
    String notificationId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse(
        '$baseUrl/notifications/$notificationId/read',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

}