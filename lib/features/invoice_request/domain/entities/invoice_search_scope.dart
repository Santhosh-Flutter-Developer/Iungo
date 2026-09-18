/// Which field(s) the Invoice Dashboard's search screen matches
/// against. Mirrors `GrnSearchScope` shape-for-shape.
enum InvoiceSearchScope {
  allFields,
  number,
  contract,
}

extension InvoiceSearchScopeX on InvoiceSearchScope {
  String get labelKey {
    switch (this) {
      case InvoiceSearchScope.allFields:
        return 'all_fields';
      case InvoiceSearchScope.number:
        return 'invoice_number';
      case InvoiceSearchScope.contract:
        return 'pr_contract';
    }
  }
}
