import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_remote_data_source.dart';
import 'package:iungo/features/purchase_request/data/models/pr_api_mapper.dart';
import 'package:iungo/features/purchase_request/data/models/pr_decision_request.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_type.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_view_role.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';
import 'package:iungo/core/network/iungo_dio.dart';
import 'package:iungo/features/purchase_request/domain/validators/pr_decision_validator.dart';

Map<String, dynamic> _record({String status = 'Pending', String state = 'O'}) => {
      'id': 118,
      'pr_number': 'DIR-26-0029',
      'pr_date': '12-Sep-2026',
      'location': 'Ardah House',
      'work_order_no': 15424,
      'contract_id': 3,
      'contract_name': 'Diriyah',
      'contract': 'Diriyah - DIR',
      'request_description': 'Replace power supply',
      'total_before_vat': '572.40',
      'vat_amount': 85.86,
      'total_amount': 658.26,
      'margin': '6',
      'status': status,
      'moduleState': state,
      'expect_date': '20-Sep-2026',
      'next_approval': 'Gladson Aby (Pending)',
      'items': [
        {
          'id': 1,
          'sno': 1,
          'material_type': 'Inventory',
          'material_code': 'Electrical Spareparts',
          'material_desc': 'Power supply',
          'quantity': '45',
          'unit_price': 12,
          'total': 540,
          'remarks': 'ok',
          'deleted': 0,
        },
        {'id': 2, 'quantity': 1, 'unit_price': 1, 'total': 1, 'deleted': 1},
      ],
      'attachments': [
        'https://iungo.citgroupltd.com/include/images/upload/Iungo_Portal_API_Guide.pdf',
      ],
      'pdf_path':
          'https://iungo.citgroupltd.com/reports/rpt_purchase_report_a4.php?view_pr_id=20&type=purchase_return',
      'delivery_notes': [],
      'invoices': null,
      'pipeline': [
        {
          'stage': 1,
          'module': 'Purchase Request',
          'state': 'O',
          'label': 'Waiting',
          'name': 'Gladson Aby',
          'sno': 1,
          'accepted_time': '2026-09-12 08:47:46.050',
          'extra_field': 'kept',
        },
      ],
    };

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Map<String, dynamic> body;
  RequestOptions? last;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

PrRemoteDataSourceImpl _source(_FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return PrRemoteDataSourceImpl(dio);
}

void main() {
  group('IungoDio', () {
    test('is a single shared instance', () {
      expect(IungoDio.instance, same(IungoDio.instance));
    });
  });

  group('PrListQuery', () {
    test('builds the documented payload when criteria are set', () {
      final json = const PrListQuery(
        userId: 'u1',
        types: 'C',
        pageLogin: 'Created',
        pageNumber: 2,
        pageLimit: 20,
        prNumber: 'DIR',
        prDate: '2026-09-01 - 2026-09-30',
        contractSearch: ['Diriyah'],
      ).toJson();

      expect(json['page_number'], '2');
      expect(json['page_limit'], '20');
      expect(json['types'], 'C');
      expect(json['page_login'], 'Created');
      expect(json['user_id'], 'u1');
      expect(json['search_data'], {
        'pr_number': 'DIR',
        'pr_date': '2026-09-01 - 2026-09-30',
        'contract_search': ['Diriyah'],
      });
    });

    test('search_data is an empty object when nothing is searched', () {
      final json = const PrListQuery(
        userId: 'u1',
        types: 'Created',
        pageLogin: 'Created',
      ).toJson();
      expect(json['search_data'], <String, dynamic>{});

      // blank strings never leak through either
      final blank = const PrListQuery(
        userId: 'u1',
        types: 'R',
        pageLogin: 'O',
        prNumber: '  ',
        prDate: '',
        contractSearch: [''],
      ).toJson();
      expect(blank['search_data'], <String, dynamic>{});
    });

    test('only the criteria that are set are sent', () {
      final json = const PrListQuery(
        userId: 'u1',
        types: 'O',
        pageLogin: 'O',
        contractSearch: ['Diriyah'],
      ).toJson();
      expect(json['search_data'], {
        'contract_search': ['Diriyah'],
      });
    });

    test('page_login follows the role, types follows the tab', () {
      expect(PrListType.pageLoginFor(PrViewRole.requestor), 'Created');
      expect(PrListType.pageLoginFor(PrViewRole.approver), 'O');
      // requestor: Submitted / Completed / Rejected
      expect(PrListType.forTab(PrViewRole.requestor, 0), 'Created');
      expect(PrListType.forTab(PrViewRole.requestor, 1), 'C');
      expect(PrListType.forTab(PrViewRole.requestor, 2), 'R');
      // approver: Action Required / Completed / Rejected
      expect(PrListType.forTab(PrViewRole.approver, 0), 'O');
      expect(PrListType.forTab(PrViewRole.approver, 1), 'C');
      expect(PrListType.forTab(PrViewRole.approver, 2), 'R');
    });

    test('tab -> types per role', () {
      expect(PrListType.forTab(PrViewRole.requestor, 0), 'Created');
      expect(PrListType.forTab(PrViewRole.approver, 0), 'O');
      expect(PrListType.forTab(PrViewRole.requestor, 1), 'C');
      expect(PrListType.forTab(PrViewRole.approver, 2), 'R');
      expect(PrListType.isActionRequired(PrViewRole.approver, 'O'), isTrue);
      expect(PrListType.isActionRequired(PrViewRole.requestor, 'O'), isFalse);
    });
  });

  group('PurchaseRequestFilter', () {
    test('sends contract NAME and a YYYY-MM-DD range', () {
      final filter = PurchaseRequestFilter(
        contract: const ContractOption(
          contractId: '3',
          contractName: 'Diriyah',
          contractCode: 'DIR',
          margin: 6,
        ),
        createdDateStart: DateTime(2026, 9, 1),
        createdDateEnd: DateTime(2026, 9, 30),
      );
      expect(filter.contractSearch, ['Diriyah']);
      expect(filter.apiDateRange, '2026-09-01 - 2026-09-30');
      expect(const PurchaseRequestFilter().apiDateRange, '');
      expect(const PurchaseRequestFilter().contractSearch, isEmpty);
    });
  });

  group('PrDecisionRequest', () {
    test('approve carries exactly one attachment file name', () {
      final json = PrDecisionRequest.approve(
        prId: 118,
        userId: 'u1',
        attachmentFileName: 'a.pdf',
      ).toJson();
      expect(json, {
        'approve_reject_pr_id': '118',
        'action_type': 'approve',
        'user_id': 'u1',
        'remarks': '',
        'selected_attachments': ['a.pdf'],
      });
    });

    test('reject carries remarks and an empty attachment string', () {
      final json = PrDecisionRequest.reject(
        prId: 97,
        userId: 'u1',
        remarks: 'Test',
      ).toJson();
      expect(json['action_type'], 'reject');
      expect(json['remarks'], 'Test');
      expect(json['selected_attachments'], '');
    });
  });

  group('PrDecisionValidator', () {
    test('approve needs exactly one attachment', () {
      expect(
        PrDecisionValidator.approveSelectionErrorKey(const []),
        'pr_select_one_attachment',
      );
      expect(
        PrDecisionValidator.approveSelectionErrorKey(const ['a', 'b']),
        'pr_select_only_one_attachment',
      );
      expect(PrDecisionValidator.approveSelectionErrorKey(const ['a']), isNull);
    });

    test('reject needs remarks up to 250 chars', () {
      expect(
        PrDecisionValidator.rejectRemarksErrorKey('   '),
        'pr_remarks_required_reject',
      );
      expect(
        PrDecisionValidator.rejectRemarksErrorKey('x' * 251),
        'pr_remarks_too_long',
      );
      expect(PrDecisionValidator.rejectRemarksErrorKey('x' * 250), isNull);
    });
  });

  group('PrApiMapper', () {
    test('maps a record', () {
      final r = PrApiMapper.record(_record())!;
      expect(r.id, 118);
      expect(r.prNumber, 'DIR-26-0029');
      expect(r.workOrderNo, '15424');
      expect(r.contract, 'Diriyah - DIR');
      expect(r.status, PurchaseRequestStatus.pending);
      expect(r.isActionable, isTrue);
      expect(r.nextApprovalName, 'Gladson Aby');
      expect(r.margin, 6);
      expect(r.totalAmount, 658.26);
      expect(r.requestDate!.toUtc().day, 12);
      expect(r.requestDate!.month, 9);
      // deleted item skipped, API total kept
      expect(r.items.length, 1);
      expect(r.items.first.total, 540);
      expect(r.totalLines, 540);
      expect(r.attachments.single.name, 'Iungo_Portal_API_Guide.pdf');
      expect(r.attachments.single.apiFileName, 'Iungo_Portal_API_Guide.pdf');
      expect(r.deliveryNotes, isEmpty);
      expect(r.invoices, isEmpty);
      expect(r.pipeline.single.extras, {'extra_field': 'kept'});
      expect(r.stageLabel, '1/1');
      expect(
        r.pdfPath,
        'https://iungo.citgroupltd.com/reports/rpt_purchase_report_a4.php?view_pr_id=20&type=purchase_return',
      );
    });

    test('pdf_path: relative paths resolve to the Iungo host, empty is null',
        () {
      final relative = _record()..['pdf_path'] = '/reports/r.php?view_pr_id=1';
      expect(
        PrApiMapper.record(relative)!.pdfPath,
        'https://iungo.citgroupltd.com/reports/r.php?view_pr_id=1',
      );
      expect(PrApiMapper.record(_record()..['pdf_path'] = '')!.pdfPath, isNull);
      expect(PrApiMapper.record(_record()..remove('pdf_path'))!.pdfPath, isNull);
    });

    test('status comes from the API, not the tab', () {
      expect(
        PrApiMapper.record(_record(status: 'Approved', state: 'C'))!.status,
        PurchaseRequestStatus.approved,
      );
      expect(
        PrApiMapper.record(_record(status: 'Rejected', state: 'R'))!.status,
        PurchaseRequestStatus.rejected,
      );
      expect(
        PrApiMapper.record(_record(status: 'Approved', state: 'C'))!
            .isActionable,
        isFalse,
      );
    });

    test('record without an id is skipped', () {
      final page = PrApiMapper.listPage(
        {
          'code': 200,
          'data': {
            'records': [
              {'pr_number': 'x'},
              _record(),
            ],
            'total_records': 1,
          },
        },
        requestedPage: 1,
        requestedLimit: 20,
      );
      expect(page.records.length, 1);
    });

    test('list page metadata', () {
      final page = PrApiMapper.listPage(
        {
          'code': 200,
          'data': {
            'page_number': 1,
            'page_limit': 20,
            'total_records': 45,
            'total_pages': 3,
            'records': [_record()],
            'add_purchase_request': 1,
            'created_status_count': 1,
            'completed_status_count': '7',
            'rejected_status_count': 1,
            'filter_options': {
              'created_by': ['a'],
              'status': ['Pending'],
              'contracts': ['Diriyah'],
            },
          },
        },
        requestedPage: 1,
        requestedLimit: 20,
      );
      expect(page.totalPages, 3);
      expect(page.addPurchaseRequest, isTrue);
      expect(page.completedStatusCount, 7);
      expect(page.filterOptions.contracts, ['Diriyah']);
    });

    test('date formats', () {
      expect(PrApiMapper.parseApiDate('12-Sep-2026')!.day, 12);
      expect(PrApiMapper.parseApiDate('2026-09-12')!.month, 9);
      expect(PrApiMapper.parseApiDate('12-09-2026')!.year, 2026);
      expect(PrApiMapper.parseApiDate('--'), isNull);
      expect(PrApiMapper.parseApiDate(null), isNull);
    });
  });

  group('ApprovalPipeline.forRequest', () {
    test('groups by module and attaches files', () {
      final json = _record();
      json['pipeline'] = [
        {'stage': 1, 'module': 'Purchase Request', 'state': 'C', 'name': 'A'},
        {'stage': 1, 'module': 'GRN', 'state': 'C', 'name': 'B'},
        {'stage': 1, 'module': 'Invoice', 'state': 'O', 'name': 'C'},
      ];
      json['delivery_notes'] = ['https://h/x/dn.pdf'];
      json['invoices'] = ['https://h/x/inv.pdf'];
      final pipeline = ApprovalPipeline.forRequest(PrApiMapper.record(json)!);

      expect(pipeline.totalStages, 3);
      expect(pipeline.currentStage, 2);
      expect(pipeline.sections.map((s) => s.title),
          ['Purchase Request', 'GRN', 'Invoice']);
      expect(pipeline.sections[0].attachmentFileNames,
          ['Iungo_Portal_API_Guide.pdf']);
      expect(pipeline.sections[1].attachmentFileNames, ['dn.pdf']);
      expect(pipeline.sections[2].attachmentFileNames, ['inv.pdf']);
      expect(pipeline.sections[2].steps.single.state, ApprovalStepState.waiting);
    });

    test('empty pipeline gives no stage progress', () {
      final json = _record()..['pipeline'] = [];
      final r = PrApiMapper.record(json)!;
      expect(r.stageLabel, '--');
      expect(ApprovalPipeline.forRequest(r).totalStages, 0);
    });
  });

  group('PrRemoteDataSourceImpl', () {
    test('list: code 200 is success and sends the JSON body via GET', () async {
      final adapter = _FakeAdapter({
        'code': 200,
        'data': {
          'records': [_record()],
          'total_records': 1,
        },
      });
      final page = await _source(adapter).fetchPurchaseRequests(
        const PrListQuery(userId: 'u1', types: 'O', pageLogin: 'O'),
      );
      expect(page.records.length, 1);
      expect(adapter.last!.method, 'GET');
      expect((adapter.last!.data as Map)['page_login'], 'O');
    });

    test('list: a non-200 code is a failure with the server message', () {
      final adapter = _FakeAdapter({'code': 1, 'message': 'Nope'});
      expect(
        _source(adapter).fetchPurchaseRequests(
          const PrListQuery(userId: 'u1', types: 'O', pageLogin: 'O'),
        ),
        throwsA(isA<PrCreateException>()),
      );
    });

    test('decision: code 0 is success', () async {
      final adapter = _FakeAdapter({'code': 0, 'message': 'Done'});
      final message = await _source(adapter).submitDecision(
        PrDecisionRequest.approve(
          prId: 1,
          userId: 'u1',
          attachmentFileName: 'a.pdf',
        ),
      );
      expect(message, 'Done');
    });

    test('decision: code 200 is NOT success for the mutation API', () {
      final adapter = _FakeAdapter({'code': 200, 'message': 'x'});
      expect(
        _source(adapter).submitDecision(
          PrDecisionRequest.reject(prId: 1, userId: 'u1', remarks: 'r'),
        ),
        throwsA(isA<PrCreateException>()),
      );
    });

    test('decision: code 1 surfaces the server message', () async {
      final adapter = _FakeAdapter({
        'code': 1,
        'message': 'Please enter remarks before rejecting the purchase request.',
      });
      try {
        await _source(adapter).submitDecision(
          PrDecisionRequest.reject(prId: 1, userId: 'u1', remarks: 'r'),
        );
        fail('should have thrown');
      } on PrCreateException catch (e) {
        expect(e.message, contains('remarks'));
      }
    });
  });
}
