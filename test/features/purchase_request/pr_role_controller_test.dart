import 'package:flutter_test/flutter_test.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_view_role.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SessionService session;
  late PrRoleController roles;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await SessionService().init();
    roles = PrRoleController(session);
  });

  test('add_purchase_request 1 -> Requestor', () {
    session.canAddPurchaseRequest.value = true;
    expect(roles.role, PrViewRole.requestor);
    expect(roles.isRequestor, isTrue);
    expect(roles.isApprover, isFalse);
  });

  test('add_purchase_request 0 -> Approver', () {
    session.canAddPurchaseRequest.value = false;
    expect(roles.role, PrViewRole.approver);
    expect(roles.isApprover, isTrue);
    expect(roles.isRequestor, isFalse);
  });

  test('unknown flag falls back to Requestor', () {
    session.canAddPurchaseRequest.value = null;
    expect(roles.isRequestor, isTrue);
  });

  test('role follows the session when the user changes', () {
    session.canAddPurchaseRequest.value = true;
    expect(roles.isRequestor, isTrue);
    session.canAddPurchaseRequest.value = false;
    expect(roles.isApprover, isTrue);
  });

  test('the flag is persisted and restored with the session', () async {
    await session.setAuthProfile(userId: 'u', addPurchaseRequest: false);
    expect(session.canAddPurchaseRequest.value, isFalse);

    final restored = await SessionService().init();
    expect(restored.canAddPurchaseRequest.value, isFalse);

    await session.setAuthProfile(userId: 'u', addPurchaseRequest: true);
    expect((await SessionService().init()).canAddPurchaseRequest.value, isTrue);
  });

  test('signing out clears the flag', () async {
    await session.setAuthProfile(userId: 'u', addPurchaseRequest: false);
    await session.clear();
    expect(session.canAddPurchaseRequest.value, isNull);
    expect((await SessionService().init()).canAddPurchaseRequest.value, isNull);
  });
}
