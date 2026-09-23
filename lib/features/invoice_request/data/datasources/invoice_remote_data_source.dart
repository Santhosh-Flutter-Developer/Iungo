import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:iungo/core/constants/app_urls.dart';
import 'package:iungo/features/invoice_request/data/models/invoice_decision_request.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/data/models/pr_api_mapper.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';

abstract class InvoiceRemoteDataSource {
  /// `GET invoice_request.php` with the list query as a JSON body.
  /// Success is body `code` 200 — same convention as the PR/GRN list
  /// APIs, and the response is the exact same record shape (see
  /// [PrApiMapper]).
  Future<PrListPage> fetchInvoiceRequests(PrListQuery query);

  /// `GET invoice_request.php` with an approve/reject body. Success is
  /// body `code` 0 (NOT 200), same as the PR/GRN decision APIs.
  Future<String?> submitDecision(InvoiceDecisionRequest request);
}

/// Talks to `https://iungo.citgroupltd.com/api/invoice_request.php`.
/// Mirrors `GrnRemoteDataSourceImpl` exactly — same request shape, same
/// success-code split between listing (200) and mutation (0) — just
/// pointed at the Invoice endpoint.
class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  InvoiceRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const int decisionSuccessCode = 0;

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
  };

  @override
  Future<PrListPage> fetchInvoiceRequests(PrListQuery query) async {
    try {
      final body = await _send(query.toJson());
      prEnsureApiSuccess(body);
      return PrApiMapper.listPage(
        body,
        requestedPage: query.pageNumber,
        requestedLimit: query.pageLimit,
      );
    } on DioException catch (e) {
      throw mapPrDioError(e);
    } on PrCreateException {
      rethrow;
    } catch (_) {
      throw const PrCreateException(PrCreateFailure.unknown);
    }
  }

  @override
  Future<String?> submitDecision(InvoiceDecisionRequest request) async {
    try {
      final body = await _send(request.toJson());
      _ensureDecisionSuccess(body);
      return prServerMessage(body);
    } on DioException catch (e) {
      throw mapPrDioError(e);
    } on PrCreateException {
      rethrow;
    } catch (_) {
      throw const PrCreateException(PrCreateFailure.unknown);
    }
  }

  Future<Map<String, dynamic>> _send(Map<String, dynamic> payload) async {
    log("payloadbuddy: $payload");
    log("URLbuddy: ${AppUrls.invoiceRequestApi}");
    final response = await _dio.request<dynamic>(
      AppUrls.invoiceRequestApi,
      data: payload,
      options: Options(
        method: 'GET',
        contentType: Headers.jsonContentType,
        headers: _jsonHeaders,
      ),
    );
    final body = prAsJsonMap(response.data);
    log("bodybuddy: $body");
    if (body == null) {
      throw const PrCreateException(PrCreateFailure.invalidResponse);
    }
    return body;
  }

  void _ensureDecisionSuccess(Map<String, dynamic> body) {
    final raw = body['code'];
    final code = raw is num
        ? raw.toInt()
        : (raw is String ? int.tryParse(raw.trim()) : null);
    if (code == null) {
      throw const PrCreateException(PrCreateFailure.invalidResponse);
    }
    if (code == decisionSuccessCode) return;

    final message = prServerMessage(body);
    if (code == 401 || code == 440) {
      throw PrCreateException(
        PrCreateFailure.unauthorized,
        message: message,
        statusCode: code,
      );
    }
    if (code == 403) {
      throw PrCreateException(
        PrCreateFailure.forbidden,
        message: message,
        statusCode: code,
      );
    }
    throw PrCreateException(
      code >= 500 ? PrCreateFailure.server : PrCreateFailure.rejected,
      message: message,
      statusCode: code,
    );
  }
}
