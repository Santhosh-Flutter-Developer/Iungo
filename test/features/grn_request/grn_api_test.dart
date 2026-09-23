import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iungo/features/grn_request/data/datasources/grn_remote_data_source.dart';
import 'package:iungo/features/grn_request/data/models/grn_decision_request.dart';
import 'package:iungo/features/grn_request/domain/validators/grn_decision_validator.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/data/models/pr_api_mapper.dart';
import 'package:iungo/features/purchase_request/data/models/pr_list_query.dart';
import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';

Map<String, dynamic> _record() => {
      'id': 134,
      'pr_number': 'DIR-26-0042',
      'pr_date': '21-Sep-2026',
      'contract_id': 'x',
      'contract_name': 'Diriyah',
      'contract': 'Diriyah - DIR',
      'status': 'Pending',
      'moduleState': 'O',
      'total_amount': 87.77,
      'attachments': [],
      'delivery_notes': [],
      'invoices': [],
      'pipeline': [
        {
          'stage': 1,
          'module': 'Purchase Request',
          'state': 'O',
          'label': 'Waiting',
          'name': 'Approver3',
          'sno': 1,
          'accepted_time': '2026-09-21 15:21:11.217',
        },
        {
          'stage': 2,
          'module': 'Purchase Request',
          'state': 'NS',
          'label': 'Next Approver',
          'name': 'prem',
          'sno': 2,
          'accepted_time': '2026-09-21 15:21:11.217',
        },
        {
          'stage': 3,
          'module': 'GRN',
          'state': 'O',
          'label': 'Waiting',
          'name': 'Approver3',
          'sno': 1,
          'accepted_time': '2026-09-21 15:21:11.217',
        },
        {
          'stage': 4,
          'module': 'GRN',
          'state': 'NS',
          'label': 'Next Approver',
          'name': 'prem',
          'sno': 2,
          'accepted_time': '2026-09-21 15:21:11.217',
        },
      ],
      'pdf_path':
          'https://iungo.citgroupltd.com/reports/rpt_purchase_report_a4.php?view_pr_id=134&type=purchase_return',
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

GrnRemoteDataSourceImpl _source(_FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return GrnRemoteDataSourceImpl(dio);
}

void main() {
  group('NS pipeline state (Next Approver)', () {
    test('maps to nextApprover and is not resolved/counted as current', () {
      final r = PrApiMapper.record(_record())!;
      // stage 1 = waiting, stage 2 = NS, stage 3 = waiting, stage 4 = NS
      // -> nothing approved/rejected yet, so current stage stays at 1.
      expect(r.pipeline[1].stepState, ApprovalStepState.nextApprover);
      expect(r.pipeline[3].stepState, ApprovalStepState.nextApprover);
      expect(r.currentStage, 1);
      expect(r.totalStages, 4);
    });

    test('ApprovalPipeline.forRequest keeps NS steps, grouped by module', () {
      final r = PrApiMapper.record(_record())!;
      final pipeline = ApprovalPipeline.forRequest(r);
      expect(pipeline.sections.map((s) => s.title),
          ['Purchase Request', 'GRN']);
      expect(pipeline.sections[0].steps.map((s) => s.state), [
        ApprovalStepState.waiting,
        ApprovalStepState.nextApprover,
      ]);
      expect(pipeline.sections[1].steps.map((s) => s.state), [
        ApprovalStepState.waiting,
        ApprovalStepState.nextApprover,
      ]);
    });
  });

  group('GrnDecisionValidator', () {
    test('approve needs at least one delivery note, any count is fine', () {
      expect(
        GrnDecisionValidator.approveRequiresDeliveryNote(const []),
        'grn_delivery_note_required_message',
      );
      expect(
        GrnDecisionValidator.approveRequiresDeliveryNote(const ['']),
        'grn_delivery_note_required_message',
      );
      expect(
        GrnDecisionValidator.approveRequiresDeliveryNote(const ['a.pdf']),
        isNull,
      );
      expect(
        GrnDecisionValidator.approveRequiresDeliveryNote(
          const ['a.pdf', 'b.pdf'],
        ),
        isNull,
      );
    });

    test('reject needs remarks up to 250 chars', () {
      expect(
        GrnDecisionValidator.rejectRemarksErrorKey('   '),
        'pr_remarks_required_reject',
      );
      expect(GrnDecisionValidator.rejectRemarksErrorKey('ok'), isNull);
    });
  });

  group('GrnDecisionRequest', () {
    test('approve carries the delivery note filenames, no remarks key', () {
      final json = GrnDecisionRequest.approve(
        grnId: 134,
        userId: 'u1',
        deliveryNoteFileNames: ['converted-image.png'],
      ).toJson();
      expect(json, {
        'approve_reject_pr_id': '134',
        'action_type': 'approve',
        'user_id': 'u1',
        'delivery_notes': ['converted-image.png'],
      });
      expect(json.containsKey('remarks'), isFalse);
    });

    test('reject carries remarks and an empty delivery_notes string', () {
      final json = GrnDecisionRequest.reject(
        grnId: 97,
        userId: 'u1',
        remarks: 'Test',
      ).toJson();
      expect(json['action_type'], 'reject');
      expect(json['remarks'], 'Test');
      expect(json['delivery_notes'], '');
    });
  });

  group('GrnRemoteDataSourceImpl', () {
    test('list: code 200 success, hits grn_request.php', () async {
      final adapter = _FakeAdapter({
        'code': 200,
        'data': {
          'records': [_record()],
          'total_records': 1,
        },
      });
      final page = await _source(adapter).fetchGrnRequests(
        const PrListQuery(userId: 'u1', types: 'O', pageLogin: 'O'),
      );
      expect(page.records.length, 1);
      expect(adapter.last!.path, contains('grn_request.php'));
    });

    test('decision: code 0 success, code 200 is NOT success', () async {
      final ok = _FakeAdapter({'code': 0, 'message': 'Done'});
      final message = await _source(ok).submitDecision(
        GrnDecisionRequest.approve(
          grnId: 1,
          userId: 'u1',
          deliveryNoteFileNames: ['a.pdf'],
        ),
      );
      expect(message, 'Done');

      final notOk = _FakeAdapter({'code': 200, 'message': 'x'});
      expect(
        _source(notOk).submitDecision(
          GrnDecisionRequest.reject(grnId: 1, userId: 'u1', remarks: 'r'),
        ),
        throwsA(isA<PrCreateException>()),
      );
    });
  });
}
