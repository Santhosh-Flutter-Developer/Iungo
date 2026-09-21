import 'package:iungo/features/purchase_request/domain/entities/pr_view_role.dart';

/// The `types` / `page_login` values of the Purchase Request list API.
///
/// `types` follows the selected tab:
///   Requestor: Submitted = `Created`, Completed = `C`, Rejected = `R`
///   Approver:  Action Required = `O`, Completed = `C`, Rejected = `R`
///
/// `page_login` follows the logged-in role and is the same on every tab:
///   Requestor = `Created`, Approver = `O`
class PrListType {
  PrListType._();

  static const String created = 'Created';
  static const String open = 'O';
  static const String completed = 'C';
  static const String rejected = 'R';

  /// Tab index 0 = Submitted / Action Required, 1 = Completed,
  /// 2 = Rejected.
  static String forTab(PrViewRole role, int tab) {
    switch (tab) {
      case 1:
        return completed;
      case 2:
        return rejected;
      default:
        return role == PrViewRole.approver ? open : created;
    }
  }

  /// `page_login` for [role] — `Created` for a requestor, `O` for an
  /// approver, whichever tab is showing.
  static String pageLoginFor(PrViewRole role) =>
      role == PrViewRole.approver ? open : created;

  /// Whether [type] is the approver's "Action Required" list — the only
  /// list whose records can be approved/rejected.
  static bool isActionRequired(PrViewRole role, String type) =>
      role == PrViewRole.approver && type == open;
}
