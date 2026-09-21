/// One entry in the "Contract Code" dropdown, from the Purchase Request
/// API's `fetch_contract_code` action. Selecting one supplies both the
/// `contract_id` sent on save and the `margin` (%) that drives the
/// Summary's "Administrative expenses".
class ContractOption {
  const ContractOption({
    required this.contractId,
    required this.contractName,
    required this.contractCode,
    required this.margin,
  });

  final String contractId;
  final String contractName;
  final String contractCode;

  /// Administrative-expense percentage for this contract (e.g. `6` = 6 %).
  final double margin;

  /// What the dropdown shows: "Diriyah - DIR" (name + code). Falls back
  /// to whichever part exists, and never repeats identical text.
  String get displayLabel {
    final name = contractName.trim();
    final code = contractCode.trim();
    if (name.isEmpty) return code;
    if (code.isEmpty || code == name) return name;
    return '$name - $code';
  }

  // Identity is the contract id, so the dropdown still highlights the
  // selected row after the list is re-fetched.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContractOption && other.contractId == contractId);

  @override
  int get hashCode => contractId.hashCode;
}
