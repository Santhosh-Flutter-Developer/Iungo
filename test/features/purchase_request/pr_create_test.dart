import 'package:flutter_test/flutter_test.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/data/models/pr_create_mapper.dart';
import 'package:iungo/features/purchase_request/data/models/pr_save_request_model.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_summary.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';

void main() {
  group('PrSummary', () {
    test('reproduces the reference payload totals (6% margin)', () {
      final s = PrSummary.calculate(
        lineTotals: const [180.0, 35415.0],
        marginPercent: 6,
      );
      expect(s.totalLines, 35595.0);
      expect(s.administrativeExpenses, 2135.7);
      expect(s.totalBeforeVat, 37730.7);
      expect(s.vatAmount, 5659.6);
      expect(s.totalAmount, 43390.3);
    });

    test('a 0% margin adds no administrative expenses', () {
      final s = PrSummary.calculate(
        lineTotals: const [100.0],
        marginPercent: 0,
      );
      expect(s.administrativeExpenses, 0.0);
      expect(s.totalBeforeVat, 100.0);
      expect(s.vatAmount, 15.0);
      expect(s.totalAmount, 115.0);
    });

    test('supports a fractional margin', () {
      final s = PrSummary.calculate(
        lineTotals: const [200.0],
        marginPercent: 6.5,
      );
      expect(s.administrativeExpenses, 13.0);
      expect(s.totalBeforeVat, 213.0);
      expect(s.vatAmount, 31.95);
      expect(s.totalAmount, 244.95);
    });

    test('an empty item list totals zero', () {
      final s = PrSummary.calculate(lineTotals: const [], marginPercent: 6);
      expect(s.totalLines, 0.0);
      expect(s.totalAmount, 0.0);
    });
  });

  group('PrSaveRequestModel', () {
    test('serialises to the documented save payload', () {
      const model = PrSaveRequestModel(
        userId: '4d6a51774e7a49774d6a59784d4445344d5456664d546b32',
        creatorName: 'santhosh',
        prDate: '18-09-2026',
        contractId: '4d6a51774e7a49774d6a59784d4445334d7a5a664d7a513d',
        expectDate: '18-09-2026',
        location: 'SVKS',
        workOrderNo: '1545/WO/478',
        purpose: 'Test Purpose',
        category: 'Cleaning',
        requestDescription: 'Test Description',
        totalBeforeVat: 37730.7,
        vatAmount: 5659.6,
        totalAmount: 43390.3,
        margin: 6,
        items: [
          PurchaseRequestItem(
            type: PurchaseRequestItemType.inventory,
            materialCode: 'Change gate valve',
            materialId: 1900,
            materialDescription:
                'Change gate valve (MIN-DR-MCH-SPR-193) (MIN-DR-MCH-CON-229)',
            quantity: 15,
            unitPrice: 12,
          ),
          PurchaseRequestItem(
            type: PurchaseRequestItemType.nonInventory,
            materialDescription: 'Test material desc',
            quantity: 787,
            unitPrice: 45,
          ),
        ],
        attachments: ['Iungo_Portal_API_Guide_1.pdf'],
      );

      expect(model.toJson(), <String, dynamic>{
        'action': 'save_purchase_request',
        'user_id': '4d6a51774e7a49774d6a59784d4445344d5456664d546b32',
        'creator_name': 'santhosh',
        'pr_id': '',
        'pr_date': '18-09-2026',
        'contract_id': '4d6a51774e7a49774d6a59784d4445334d7a5a664d7a513d',
        'expect_date': '18-09-2026',
        'location': 'SVKS',
        'work_order_no': '1545/WO/478',
        'p_val': 'Test Purpose',
        'category': 'Cleaning',
        'total_before_vat': 37730.7,
        'request_description': 'Test Description',
        'vat_amount': 5659.6,
        'total_amount': 43390.3,
        'margin': 6,
        'items': [
          {
            'id': '',
            'sno': 1,
            'material_type': 'Inventory',
            'material_code': 'Change gate valve',
            'material_desc':
                'Change gate valve (MIN-DR-MCH-SPR-193) (MIN-DR-MCH-CON-229)',
            'quantity': 15,
            'unit_price': 12,
            'total': 180.0,
            'remarks': '',
            'ids': 1900,
          },
          {
            'id': '',
            'sno': 2,
            'material_type': 'Non Inventory',
            'material_code': '-',
            'material_desc': 'Test material desc',
            'quantity': 787,
            'unit_price': 45,
            'total': 35415.0,
            'remarks': '',
            'ids': '',
          },
        ],
        'attachments': ['Iungo_Portal_API_Guide_1.pdf'],
      });
    });
  });

  group('ContractOption', () {
    test('label shows contract name + code', () {
      const contract = ContractOption(
        contractId: '1',
        contractName: 'Diriyah',
        contractCode: 'DIR',
        margin: 6,
      );
      expect(contract.displayLabel, 'Diriyah - DIR');
    });

    test('label never repeats identical name and code', () {
      const contract = ContractOption(
        contractId: '1',
        contractName: 'DIR',
        contractCode: 'DIR',
        margin: 6,
      );
      expect(contract.displayLabel, 'DIR');
    });
  });

  group('PrCreateMapper', () {
    test('parses contract codes with their margin', () {
      final contracts = PrCreateMapper.contracts({
        'code': 200,
        'data': [
          {
            'contract_id': '4d6a51774e7a49774d6a59784d4445334d7a5a664d7a513d',
            'contract_name': 'Diriyah',
            'contract_code': 'DIR',
            'margin': 6,
          },
          {'contract_name': 'No id — skipped', 'contract_code': 'X'},
        ],
        'message': 'Contract codes fetched successfully.',
      });

      expect(contracts, hasLength(1));
      expect(contracts.first.contractCode, 'DIR');
      expect(contracts.first.contractName, 'Diriyah');
      expect(contracts.first.margin, 6.0);
    });

    test('an empty contract response yields an empty list', () {
      expect(PrCreateMapper.contracts({'code': 200, 'data': []}), isEmpty);
      expect(PrCreateMapper.contracts({'code': 200}), isEmpty);
    });

    test('extracts only id, name and description of materials', () {
      final page = PrCreateMapper.materials({
        'code': 0,
        'data': {
          'inventoryrequest': [
            {
              'id': 1922,
              'name': 'Electrical Consumables-Strip Light Holder',
              'description': 'Additional material related to 1429539',
              'orgId': 500000029,
            },
            {'id': '5', 'name': 'No description'},
            {'name': 'No id — skipped'},
          ],
        },
      });

      expect(page.rawCount, 3);
      expect(page.items, hasLength(2));
      expect(page.items.first.id, 1922);
      expect(page.items.first.name, 'Electrical Consumables-Strip Light Holder');
      expect(page.items.first.description,
          'Additional material related to 1429539');
      expect(page.items.last.id, 5);
      expect(page.items.last.description, '');
    });

    test('uses saved_name from the upload response', () {
      expect(
        PrCreateMapper.uploadedFileName({
          'code': 200,
          'data': {
            'file_name': 'Iungo Portal API Guide (1).pdf',
            'saved_name': 'Iungo_Portal_API_Guide_1.pdf',
          },
        }),
        'Iungo_Portal_API_Guide_1.pdf',
      );
    });

    test('an upload response without a filename is invalid', () {
      expect(
        () => PrCreateMapper.uploadedFileName({'code': 200, 'data': {}}),
        throwsA(isA<PrCreateException>()),
      );
    });
  });

  group('prEnsureApiSuccess', () {
    test('accepts code 200', () {
      expect(() => prEnsureApiSuccess({'code': 200}), returnsNormally);
    });

    test('maps auth codes to unauthorized', () {
      expect(
        () => prEnsureApiSuccess({'code': 401}),
        throwsA(
          isA<PrCreateException>()
              .having((e) => e.type, 'type', PrCreateFailure.unauthorized),
        ),
      );
    });

    test('carries the server message for other failures', () {
      expect(
        () => prEnsureApiSuccess({'code': 400, 'message': 'Invalid contract'}),
        throwsA(
          isA<PrCreateException>()
              .having((e) => e.type, 'type', PrCreateFailure.rejected)
              .having((e) => e.message, 'message', 'Invalid contract'),
        ),
      );
    });

    test('a body without a code is invalid', () {
      expect(
        () => prEnsureApiSuccess({'data': []}),
        throwsA(
          isA<PrCreateException>()
              .having((e) => e.type, 'type', PrCreateFailure.invalidResponse),
        ),
      );
    });
  });
}
