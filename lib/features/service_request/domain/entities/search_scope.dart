enum SearchScope {
  allFields,
  ticketId,
}

extension SearchScopeX on SearchScope {
  String get labelKey {
    switch (this) {
      case SearchScope.allFields:
        return 'all_fields';
      case SearchScope.ticketId:
        return 'ticket_id';
    }
  }
}
