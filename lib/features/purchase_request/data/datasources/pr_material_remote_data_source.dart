import 'package:dio/dio.dart';
import 'package:iungo/core/constants/app_urls.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/data/models/pr_create_mapper.dart';

abstract class PrMaterialRemoteDataSource {
  /// One page (1-indexed [page]) of the Facilio inventory list behind the
  /// Inventory "Material Code" dropdown:
  ///
  ///   GET .../v3/modules/inventoryrequest/view/allinventoryrequests?
  ///       fetchOnlyViewGroupColumn=true&moduleName=inventoryrequest&
  ///       viewName=allinventoryrequests&page=<page>&perPage=<perPage>&
  ///       withoutCustomButtons=true&search=<search>
  ///
  /// Uses a static bearer token (not the login session's), and only rows
  /// flagged `is_spare_part_request_or_not_inventoryrequest == 1` are
  /// returned in `items`.
  ///
  /// [search] is applied server-side, so typing in the dropdown never
  /// needs the whole catalogue in memory.
  Future<MaterialPageResult> fetchMaterials({
    required int page,
    required int perPage,
    String search = '',
  });
}

class PrMaterialRemoteDataSourceImpl implements PrMaterialRemoteDataSource {
  PrMaterialRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _moduleName = 'inventoryrequest';
  static const String _viewName = 'allinventoryrequests';

  @override
  Future<MaterialPageResult> fetchMaterials({
    required int page,
    required int perPage,
    String search = '',
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        AppUrls.inventoryMaterialsApi,
        queryParameters: {
          'fetchOnlyViewGroupColumn': true,
          'moduleName': _moduleName,
          'viewName': _viewName,
          'page': page,
          'perPage': perPage,
          'withoutCustomButtons': true,
          'search': search,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${AppUrls.inventoryMaterialsStaticToken}',
          },
        ),
      );

      final body = prAsJsonMap(response.data);
      if (body == null) {
        throw const PrCreateException(PrCreateFailure.invalidResponse);
      }

      // Facilio reports success as `code: 0`.
      final code = body['code'];
      if (code != null && code.toString() != '0') {
        throw PrCreateException(
          PrCreateFailure.rejected,
          message: prServerMessage(body),
        );
      }

      return PrCreateMapper.materials(body);
    } on DioException catch (e) {
      throw mapPrDioError(e);
    } on PrCreateException {
      rethrow;
    } catch (_) {
      throw const PrCreateException(PrCreateFailure.unknown);
    }
  }
}