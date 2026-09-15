/// Which field(s) the PR Dashboard's search screen matches against.
/// Mirrors `SearchScope` (used by Service Request/Work
/// Order/Inventory Request search) shape-for-shape, with PR Number in
/// place of Ticket Id and Contract in place of Subject/Description —
/// the two fields `PrSearchController` has always matched against.
enum PrSearchScope {
  allFields,
  prNumber,
  contract,
}

extension PrSearchScopeX on PrSearchScope {
  String get labelKey {
    switch (this) {
      case PrSearchScope.allFields:
        return 'all_fields';
      case PrSearchScope.prNumber:
        return 'pr_number';
      case PrSearchScope.contract:
        return 'pr_contract';
    }
  }
}