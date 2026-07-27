import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constant.dart';
import 'auth_service.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstant.baseUrl,
      connectTimeout: const Duration(seconds: 60), // increase from 10 to 60
      receiveTimeout: const Duration(seconds: 60), // increase from 10 to 60
      headers: {'x-requested-with': 'flutter'},
    ),
  );

  // ─── Setup interceptor for JWT auto-refresh ───────────────────
  static void init() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // attach access token to every request
          final token = await AuthService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // if 401 — token expired, try refresh
          if (error.response?.statusCode == 401) {
            final newToken = await AuthService.refreshAccessToken(
              AppConstant.baseUrl,
            );

            if (newToken != null) {
              // retry original request with new token
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ─── Auth ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login to: ${AppConstant.baseUrl}/'); // add this
      final response = await _dio.post(
        '/',
        data: {'email': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      print('Login response: ${response.data}'); // add this
      return response.data;
    } on DioException catch (e) {
      print('Login error type: ${e.type}'); // add this
      print('Login error message: ${e.message}'); // add this
      print('Login error response: ${e.response?.data}'); // add this
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required File image,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'password': password,
        'image': await MultipartFile.fromFile(
          image.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post('/register', data: formData);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> refreshToken(String token) async {
    try {
      final response = await _dio.post(
        '/refresh-token',
        data: {'refreshToken': token},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ─── Users ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final response = await _dio.get('/api/users');
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ─── 1-on-1 Chat ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> saveChat({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/save-chat',
        data: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': message,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteChat(String chatId) async {
    try {
      final response = await _dio.post(
        '/delete-chat',
        data: {'chatId': chatId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateChat({
    required String chatId,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/update-chat',
        data: {'chatId': chatId, 'message': message},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ─── Groups ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getGroups() async {
    try {
      final response = await _dio.get('/groups');
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required int limit,
    required File image,
  }) async {
    try {
      final formData = FormData.fromMap({
        'group_name': name,
        'limit': limit,
        'image': await MultipartFile.fromFile(
          image.path,
          filename: 'group_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post('/groups', data: formData);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> joinGroup(String groupId) async {
    try {
      final response = await _dio.post(
        '/join-group',
        data: {'group_id': groupId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getMembers(String groupId) async {
    try {
      final response = await _dio.post(
        '/get-members',
        data: {'group_id': groupId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> addMembers({
    required String groupId,
    required List<String> members,
    required int limit,
  }) async {
    try {
      final response = await _dio.post(
        '/add-members',
        data: {'group_id': groupId, 'members[]': members, 'limit': limit},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ─── Group Chat ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> saveGroupChat({
    required String senderId,
    required String groupId,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/group-save-chat',
        data: {'sender_id': senderId, 'group_id': groupId, 'message': message},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> loadGroupChats(String groupId) async {
    try {
      final response = await _dio.post(
        '/load-group-chats',
        data: {'group_id': groupId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteGroupChat(String chatId) async {
    try {
      final response = await _dio.post(
        '/delete-group-chat',
        data: {'id': chatId},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateGroupChat({
    required String chatId,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/update-group-chat',
        data: {'id': chatId, 'message': message},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ─── Error handler ────────────────────────────────────────────

  static Map<String, dynamic> _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return {
        'success': false,
        'message': 'Connection timed out. Check your internet.',
      };
    }
    if (e.type == DioExceptionType.connectionError) {
      return {
        'success': false,
        'message': 'Cannot reach server. Check your connection.',
      };
    }
    return {
      'success': false,
      'message': e.response?.data['message'] ?? 'Something went wrong.',
    };
  }
}
