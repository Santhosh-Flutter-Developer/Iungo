import 'package:dio/dio.dart';
import 'package:iungo/core/constants/app_urls.dart';
import 'package:iungo/core/services/session_service.dart';
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
  /// [search] is applied server-side, so typing in the dropdown never
  /// needs the whole catalogue in memory.
  Future<MaterialPageResult> fetchMaterials({
    required int page,
    required int perPage,
    String search = '',
  });
}

class PrMaterialRemoteDataSourceImpl implements PrMaterialRemoteDataSource {
  PrMaterialRemoteDataSourceImpl(this._dio, this._session);

  final Dio _dio;
  final SessionService _session;

  static const String _moduleName = 'inventoryrequest';
  static const String _viewName = 'allinventoryrequests';

  @override
  Future<MaterialPageResult> fetchMaterials({
    required int page,
    required int perPage,
    String search = '',
  }) async {
    // The bearer token comes from the login session — never hard-coded.
    final token = _session.token.value;
    if (token == null || token.isEmpty) {
      throw const PrCreateException(PrCreateFailure.unauthorized);
    }

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
            'Authorization': 'Bearer $token',
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
