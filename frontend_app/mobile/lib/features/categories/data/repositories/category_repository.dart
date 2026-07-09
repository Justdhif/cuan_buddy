import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class CategoryRepository {
  CategoryRepository({required this.dioClient});

  final DioClient dioClient;

  Dio get _dio => dioClient.dio;

  Future<List<dynamic>> getCategories({int page = 1, int limit = 100}) async {
    final response = await _dio.get('/categories', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return response.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? emojiIcon,
    String? colorCode,
  }) async {
    final response = await _dio.post('/categories', data: {
      'name': name,
      'emojiIcon': emojiIcon,
      'colorCode': colorCode ?? '#4F46E5', // Default primary color
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCategory({
    required String id,
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.patch('/categories/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }
}
