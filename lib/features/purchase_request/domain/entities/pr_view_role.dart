/// Which of the two PR-flow UIs is shown — the "Add" button only ever
/// shows for [requestor], and Approve/Reject actions only ever show for
/// [approver]. Applies to the PR, GRN and Invoice dashboards.
///
/// The role is decided server-side per user: the login response's
/// `add_purchase_request` flag is `1` for a requestor and `0` for an
/// approver (see `PrRoleController`). There is no UI for choosing it.
enum PrViewRole { requestor, approver }

extension PrViewRoleX on PrViewRole {
  String get labelKey {
    switch (this) {
      case PrViewRole.requestor:
        return 'pr_role_requestor';
      case PrViewRole.approver:
        return 'pr_role_approver';
    }
  }
}
