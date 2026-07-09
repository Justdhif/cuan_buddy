import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class ProfileRepository {
  ProfileRepository({required this.dioClient});

  final DioClient dioClient;

  Dio get _dio => dioClient.dio;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/profiles/me');
    return response.data as Map<String, dynamic>;
  }

  Future<void> submitFeedback(String message) async {
    await _dio.post('/feedback', data: {'message': message});
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? username,
    String? phoneNumber,
    String? currency,
    String? birthDate,
    String? gender,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (username != null) body['username'] = username;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (currency != null) body['currency'] = currency;
    if (birthDate != null) body['birthDate'] = birthDate;
    if (gender != null) body['gender'] = gender;
    if (bio != null) body['bio'] = bio;

    final response = await _dio.patch('/profiles/me', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAvatar({required String avatarUrl}) async {
    final response =
        await _dio.patch('/profiles/avatar', data: {'avatar': avatarUrl});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBackupSettings() async {
    final response = await _dio.get('/backup/settings');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBackupSettings({
    required bool isEnabled,
    required String interval,
  }) async {
    final response = await _dio.put('/backup/settings', data: {
      'isEnabled': isEnabled,
      'interval': interval,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> downloadBackup(String savePath,
      {List<String> tables = const [],
      Function(int, int)? onReceiveProgress}) async {
    final query = tables.isNotEmpty ? '?tables=${tables.join(',')}' : '';
    await _dio.download(
      '/backup/export$query',
      savePath,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<void> downloadTemplate(String table, String savePath,
      {Function(int, int)? onReceiveProgress}) async {
    await _dio.download(
      '/backup/template/$table',
      savePath,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<void> markBackupCompleted() async {
    await _dio.post('/backup/mark-completed');
  }

  Future<void> uploadRestore(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    await _dio.post(
      '/backup/import',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
