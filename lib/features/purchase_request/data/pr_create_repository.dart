import 'package:dio/dio.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_material_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/models/pr_create_mapper.dart';
import 'package:iungo/features/purchase_request/data/models/pr_save_request_model.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

/// Everything the "Add Purchase Request" form needs from the network:
/// contract codes, inventory materials, attachment upload and the final
/// save. Kept separate from [PurchaseRequestRepository] (the local,
/// seed-data-backed list used by the dashboard) so neither is affected
/// by the other.
class PrCreateRepository {
  PrCreateRepository(this._remote, this._materials);

  final PrCreateRemoteDataSource _remote;
  final PrMaterialRemoteDataSource _materials;

  Future<List<ContractOption>> fetchContracts({required String userId}) =>
      _remote.fetchContracts(userId: userId);

  Future<MaterialPageResult> fetchMaterials({
    required int page,
    required int perPage,
    String search = '',
  }) =>
      _materials.fetchMaterials(page: page, perPage: perPage, search: search);

  Future<String> uploadAttachment(
    AttachmentFile file, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) =>
      _remote.uploadAttachment(
        file,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );

  Future<String?> savePurchaseRequest(PrSaveRequestModel request) =>
      _remote.savePurchaseRequest(request);
}
