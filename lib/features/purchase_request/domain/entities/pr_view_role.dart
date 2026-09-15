/// Which of the two PR Dashboard UIs is being shown — the "Add" button
/// only ever shows for [requestor], and Approve/Reject actions only
/// ever show for [approver] (see the reference videos).
///
/// In production this is decided server-side per the logged-in user;
/// there is no UI for the person to choose their own role. Until that
/// API is wired up, [PrRoleController] defaults to [requestor] and
/// exposes a small dev-only switch (see `PrRoleSwitch`) purely so both
/// UIs can be previewed in the running app — that switch is expected to
/// be removed once the real role comes from the session/API.
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
