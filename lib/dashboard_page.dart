import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  String data = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchProtectedData();
  }

  Future<void> fetchProtectedData() async {
    print("FETCHING PROTECTED DATA");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print("TOKEN: $token");

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/protected'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        data = decoded['message'];
      });
    } else {
      setState(() {
        data = "Unauthorized / Failed";
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.contains("message")
                  ? "Protected API Wprking"
                  : data,
              style: const TextStyle(fontSize: 18),    

            ),
          
          ],
        ),
      ),
    );
  }
}