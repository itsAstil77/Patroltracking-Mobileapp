// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/models/checklist.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:patroltracking/models/workflow.dart';

class ApiService {
  static final String _baseUrl = AppConstants.baseUrl;

// login api request
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password.trim(),
        }),
      );

      return {
        'status': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'status': 500,
        'body': {'success': false, 'message': 'Something went wrong!'},
      };
    }
  }

// otp verification api request
  static Future<Map<String, dynamic>> verifyOtp({
    required String username,
    required String otp,
  }) async {
    final url = Uri.parse('$_baseUrl/login/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'otp': otp,
        }),
      );

      return {
        'status': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'status': 500,
        'body': {'success': false, 'message': 'Something went wrong!'},
      };
    }
  }

//fetch assigned checklist events
  // static Future<List<EventChecklistGroup>> fetchGroupedChecklists(
  //     String patrolCode, String token) async {
  //   final response = await http.get(
  //     Uri.parse('$_baseUrl/checklists/grouped/$patrolCode'),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final responseData = json.decode(response.body);
  //     final eventsData = responseData['data'] as List;

  //     return eventsData.map((e) => EventChecklistGroup.fromJson(e)).toList();
  //   } else {
  //     throw Exception('Failed to load grouped checklists');
  //   }
  // }

  static Future<List<EventChecklistGroup>> fetchGroupedChecklists(
      String patrolId, String token) async {
    final url = Uri.parse('$_baseUrl/checklists/grouped/$patrolId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final List<dynamic> dataList = jsonBody['data'] ?? [];

        return dataList.map((e) => EventChecklistGroup.fromJson(e)).toList();
      } else {
        throw Exception(
            'Failed to load grouped checklists: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching grouped checklists: $e');
    }
  }

// start time update api in workflow
  static Future<bool> startWorkflow(String workflowId, String token) async {
    final url = Uri.parse('$_baseUrl/workflow/start/$workflowId');

    final startTime = DateTime.now().toUtc().toIso8601String();

    final body = jsonEncode({
      'startDateTime': startTime,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return true;
      } else {
        print('❌ Server returned ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception during startWorkflow: $e');
      return false;
    }
  }

// checklist get api
  // static Future<List<Checklist>> getAssignedChecklists({
  //   required String assignedTo,
  //   String status = 'Open',
  //   required String token, // Pass the token as a parameter
  // }) async {
  //   final url = Uri.parse(
  //       '$_baseUrl/checklists/assigned?assignedTo=$assignedTo&status=$status&isActive=true');

  //   final response = await http.get(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final decoded = jsonDecode(response.body);
  //     final List checklists = decoded['checklists'];
  //     return checklists.map((e) => Checklist.fromJson(e)).toList();
  //   } else {
  //     throw Exception('Failed to load checklists');
  //   }
  // }

//fetch the scanner location
  static Future<Map<String, dynamic>?> fetchLocationByCode(
      String locationCode) async {
    final url = Uri.parse('$_baseUrl/locationcode/$locationCode');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print("Failed to fetch location. Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("API error: $e");
      return null;
    }
  }

// create scanning record
  static Future<Map<String, dynamic>> submitScan({
    required String scanType,
    required String checklistId,
    required String token,
  }) async {
    final url = Uri.parse("$_baseUrl/scanning");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "scanType": scanType,
        "checklistId": checklistId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to submit scan. Status: ${response.statusCode}");
    }
  }

// fetch the checklist agaist the selected event
  static Future<List<Map<String, dynamic>>> fetchWorkflowPatrolChecklists({
    required String workflowId,
    required String patrolId,
    required String token,
  }) async {
    final url = Uri.parse(
        "$_baseUrl/workflow/workflow-patrol?workflowId=$workflowId&patrolId=$patrolId");

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['checklists'] != null && data['checklists'] is List) {
        return List<Map<String, dynamic>>.from(data['checklists']);
      } else {
        return [];
      }
    } else {
      final data = jsonDecode(response.body);
      final errorMessage =
          data['message'] ?? "Failed to fetch patrol checklists.";
      throw Exception(errorMessage);
    }
  }

// insert signature
  static Future<Map<String, dynamic>> uploadSignature({
    required File signatureFile,
    required String patrolId,
    required String checklistId,
    required String token, // Added token parameter
  }) async {
    final uri = Uri.parse("$_baseUrl/signature");

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token' // Adding the bearer token
      ..fields['patrolId'] = patrolId
      ..fields['checklistId'] = checklistId
      ..files.add(await http.MultipartFile.fromPath(
        'signatureImage',
        signatureFile.path,
        contentType: MediaType('image', 'jpg'),
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to upload signature: ${response.body}");
    }
  }

// insert multimedia
  static Future<http.Response> uploadMultimedia({
    required String token,
    required String checklistId,
    required File mediaFile,
    required String mediaType,
    required String description,
    required String patrolId,
    required String createdBy,
  }) async {
    final uri = Uri.parse('$_baseUrl/media');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    final mimeTypeData = lookupMimeType(mediaFile.path)?.split('/');
    if (mimeTypeData == null) throw Exception("Unknown mime type");
    request.fields['checklistId'] = checklistId;
    request.fields['mediaType'] = mediaType;
    request.fields['description'] = description;
    request.fields['patrolId'] = patrolId;
    request.fields['createdBy'] = createdBy;

    request.files.add(await http.MultipartFile.fromPath(
      'mediaFile',
      mediaFile.path,
      contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
    ));

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

// update endtime of the checklist once the tick icon clicked
  static Future<String> updateScanEndTime(
      String checklistId, String token) async {
    final url = Uri.parse('$_baseUrl/checklists/end/$checklistId');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          return body['message'];
        } else {
          throw Exception(body['message'] ?? 'Failed to update end time');
        }
      } else {
        throw Exception(
            'Failed to update scan end time: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating scan end time: $e');
    }
  }

// update checklist API as Completed
  static Future<String?> completeChecklists(
    List<String> checklistIds,
    String token,
  ) async {
    final url = Uri.parse('$_baseUrl/checklists/complete');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "checklistIds": checklistIds,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['message'];
      } else {
        print('Failed to complete checklists: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error completing checklists: $e');
      return null;
    }
  }

// update end time and status completed in workflow
  static Future<bool> completeWorkflow(String workflowId, String token) async {
    final url = Uri.parse('$_baseUrl/workflow/done/$workflowId');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return true;
      } else {
        print('❌ Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception during workflow completion: $e');
      return false;
    }
  }

//incident list fetching
  static Future<List<Map<String, dynamic>>> fetchIncidents(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/incidentmaster'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // if needed
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to load incidents");
    }
  }

//create Incident records
  static Future<Map<String, dynamic>> sendIncidents({
    required String token,
    required String patrolId,
    required List<String> incidentCodes,
  }) async {
    final url = Uri.parse('$_baseUrl/incident');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "patrolId": patrolId,
      "incidentCodes": incidentCodes,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to send incidents: ${response.body}");
    }
  }

//get completed workflow history
  Future<List<WorkflowData>> getCompletedWorkflows(
      String patrolId, String token) async {
    final url = Uri.parse('$_baseUrl/workflow/completed/$patrolId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List workflows =
            data['data']; // Adjust according to actual response
        return workflows.map((e) => WorkflowData.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        // No completed workflows found — return empty list
        return [];
      } else {
        // For any other error, throw an exception
        throw Exception('Failed to load workflows: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching completed workflows: $e');
    }
  }
}