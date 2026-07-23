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

  Future<List<dynamic>> getAvatarBorders() async {
    final response = await _dio.get('/borders/avatars');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getBannerBorders() async {
    final response = await _dio.get('/borders/banners');
    return response.data as List<dynamic>;
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
    String? bannerType,
    String? bannerColor,
    String? bannerImage,
    String? bannerBorder,
    String? avatarWings,
    String? listBackground,
    bool clearListBackground = false,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (username != null) body['username'] = username;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (currency != null) body['currency'] = currency;
    if (birthDate != null) body['birthDate'] = birthDate;
    if (gender != null) body['gender'] = gender;
    if (bio != null) body['bio'] = bio;
    if (bannerType != null) body['bannerType'] = bannerType;
    if (bannerColor != null) body['bannerColor'] = bannerColor;
    if (bannerImage != null) body['bannerImage'] = bannerImage;
    if (bannerBorder != null) body['bannerBorder'] = bannerBorder;
    if (avatarWings != null) body['avatarWings'] = avatarWings;

    if (clearListBackground) {
      body['listBackground'] = null;
    } else if (listBackground != null) {
      body['listBackground'] = listBackground;
    }

    final response = await _dio.patch('/profiles/me', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAvatar({required String avatarUrl}) async {
    final response =
        await _dio.patch('/profiles/avatar', data: {'avatar': avatarUrl});
    return response.data as Map<String, dynamic>;
  }

  /// Menyimpan pilihan border avatar ke server agar bisa dilihat user lain.
  Future<void> updateBorder({required String borderId}) async {
    await _dio.patch('/profiles/me', data: {'avatarBorder': borderId});
  }

  /// Menyimpan pilihan wings avatar ke server agar bisa dilihat user lain.
  Future<void> updateWings({required String wingsId}) async {
    await _dio.patch('/profiles/me', data: {'avatarWings': wingsId});
  }

  /// Menyimpan pilihan border banner ke server agar bisa dilihat user lain.
  Future<void> updateBannerBorder({required String borderId}) async {
    await _dio.patch('/profiles/me', data: {'bannerBorder': borderId});
  }

  /// Mengambil list ID border yang telah di-unlock secara permanen oleh user dari server.
  Future<List<String>> getUnlockedBorders() async {
    final response = await _dio.get('/profiles/unlocked-borders');
    if (response.data is List) {
      return List<String>.from(response.data);
    }
    return [];
  }

  /// Meminta server untuk mengevaluasi ulang pencapaian user dan meng-unlock border baru.
  Future<Map<String, dynamic>> checkAchievements() async {
    final response = await _dio.post('/profiles/check-achievements');
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

