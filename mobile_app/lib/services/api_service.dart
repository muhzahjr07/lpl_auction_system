import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl =
      'https://fritz-diminishable-disenchantedly.ngrok-free.dev/api';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null) {
      baseUrl = '$savedUrl/api';
    } else {
      // Default to ngrok as requested by user
      baseUrl = 'https://fritz-diminishable-disenchantedly.ngrok-free.dev/api';
    }
  }

  Future<void> updateUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (!newUrl.startsWith('http')) {
      newUrl = 'http://$newUrl';
    }
    await prefs.setString('server_url', newUrl);
    baseUrl = '$newUrl/api';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders([String? token]) async {
    final headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: await _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load stats');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setInt('userId', data['user_id'] ?? 0);
        await prefs.setString('email', email); // Save email for display

        if (data['team'] != null) {
          await prefs.setInt('teamId', data['team']['team_id']);
          await prefs.setString('teamName', data['team']['team_name']);
          if (data['team']['logo_url'] != null) {
            String logo = data['team']['logo_url'];
            if (!logo.startsWith('http')) {
              logo = '$baseUrl/$logo'.replaceAll('/api/', '/');
            }
            await prefs.setString('teamLogo', logo);
          }
        }

        return {'success': true, 'role': data['role']};
      } else {
        return {'success': false, 'message': 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getPlayers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/players'),
      headers: await _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getUnsoldPlayers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/auction/unsold'),
      headers: await _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> getPlayerById(int id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/players/$id'),
      headers: await _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load player');
  }

  Future<List<dynamic>> getTeams() async {
    final response = await http.get(
      Uri.parse('$baseUrl/teams'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> getTeamById(int id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/teams/$id'),
      headers: await _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load team');
  }

  Future<bool> addPlayer(Map<String, dynamic> playerData) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/players'),
      headers: await _getHeaders(token),
      body: jsonEncode(playerData),
    );
    return response.statusCode == 201;
  }

  Future<bool> updatePlayer(int id, Map<String, dynamic> playerData) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/players/$id'),
      headers: await _getHeaders(token),
      body: jsonEncode(playerData),
    );
    return response.statusCode == 200;
  }

  Future<bool> deletePlayer(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/players/$id'),
      headers: await _getHeaders(token),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getAuctionState() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/auction/state'),
      headers: await _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<bool> startRound(int playerId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auction/start'),
      headers: await _getHeaders(token),
      body: jsonEncode({'playerId': playerId}),
    );
    return response.statusCode == 200;
  }

  Future<bool> markUnsold(int playerId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auction/unsold'),
      headers: await _getHeaders(token),
      body: jsonEncode({'playerId': playerId}),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: await _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load users');
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: await _getHeaders(token),
      body: jsonEncode(userData),
    );
    return response.statusCode == 201;
  }

  Future<bool> deleteUser(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _getHeaders(token),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _getHeaders(token),
      body: jsonEncode(userData),
    );
    return response.statusCode == 200;
  }

  Future<bool> resetAuction() async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auction/reset'),
      headers: await _getHeaders(token),
      body: jsonEncode({}),
    );
    return response.statusCode == 200;
  }

  Future<bool> resetDatabase() async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/reset-db'),
      headers: await _getHeaders(token),
    );
    return response.statusCode == 200;
  }
}
