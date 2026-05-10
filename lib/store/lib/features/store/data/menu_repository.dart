import 'package:dio/dio.dart';
import 'package:campuschow/store/lib/core/network/api_client.dart';
import 'package:campuschow/store/lib/core/error/result.dart';
import 'package:campuschow/store/lib/core/error/failures.dart';
import 'package:campuschow/store/lib/features/store/data/menu_item_model.dart';
import 'package:campuschow/store/lib/features/store/data/store_model.dart';

class MenuRepository {
  Future<Result<List<MenuItem>>> getMenuItems() async {
    try {
      final response = await apiService.dio.get('/menu');
      final items = (response.data as List).map((i) => MenuItem.fromJson(i)).toList();
      return Result.success(items);
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final response = await apiService.dio.put('/menu/$id', data: data);
      return Result.success(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> addMenuItem(Map<String, dynamic> data) async {
    try {
      final response = await apiService.dio.post('/menu', data: data);
      return Result.success(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<Store>>> getStores() async {
    try {
      final response = await apiService.dio.get('/stores');
      final stores = (response.data as List).map((i) => Store.fromJson(i)).toList();
      return Result.success(stores);
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteMenuItem(String id) async {
    try {
      await apiService.dio.delete('/menu/$id');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(apiService.handleDioError(e));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final menuRepository = MenuRepository();
