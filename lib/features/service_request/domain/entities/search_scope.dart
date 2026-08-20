enum SearchScope {
  allFields,
  ticketId,
  subject,
  description,
}

extension SearchScopeX on SearchScope {
  String get labelKey {
    switch (this) {
      case SearchScope.allFields:
        return 'all_fields';
      case SearchScope.ticketId:
        return 'ticket_id';
      case SearchScope.subject:
        return 'subject';
      case SearchScope.description:
        return 'description';
    }
  }
}