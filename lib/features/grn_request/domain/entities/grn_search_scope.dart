/// Which field(s) the GRN Dashboard's search screen matches against.
/// Mirrors `PrSearchScope` shape-for-shape.
enum GrnSearchScope {
  allFields,
  number,
  contract,
}

extension GrnSearchScopeX on GrnSearchScope {
  String get labelKey {
    switch (this) {
      case GrnSearchScope.allFields:
        return 'all_fields';
      case GrnSearchScope.number:
        return 'grn_number';
      case GrnSearchScope.contract:
        return 'pr_contract';
    }
  }
}
