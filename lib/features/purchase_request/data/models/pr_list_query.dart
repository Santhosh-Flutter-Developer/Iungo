/// The request body of the Purchase Request list API:
///
/// ```json
/// {
///   "page_number": "1",
///   "page_limit": "20",
///   "search_data": {},
///   "types": "C",
///   "page_login": "Created",
///   "user_id": "<logged-in user id>"
/// }
/// ```
///
/// `types` is the tab being listed (`Created` / `O` / `C` / `R`), while
/// `page_login` identifies the logged-in role's portal and stays the
/// same on every tab: `Created` for a requestor, `O` for an approver
/// (see `PrListType`).
///
/// `search_data` only carries the criteria that are actually set —
/// `pr_number`, `pr_date` and `contract_search` are each left out when
/// empty, so with no search or filter it is an empty object.
class PrListQuery {
  const PrListQuery({
    required this.userId,
    required this.types,
    required this.pageLogin,
    this.pageNumber = 1,
    this.pageLimit = 20,
    this.prNumber = '',
    this.prDate = '',
    this.contractSearch = const [],
  });

  /// The logged-in user's id — always taken from the session, never
  /// hard-coded.
  final String userId;

  /// `Created` / `O` / `C` / `R`.
  final String types;

  /// `Created` (requestor) / `O` (approver) — independent of the tab.
  final String pageLogin;

  final int pageNumber;
  final int pageLimit;

  /// `search_data.pr_number` — server-side PR number search.
  final String prNumber;

  /// `search_data.pr_date` — `YYYY-MM-DD - YYYY-MM-DD` or empty.
  final String prDate;

  /// `search_data.contract_search` — selected contract name(s).
  final List<String> contractSearch;

  PrListQuery copyWith({int? pageNumber}) {
    return PrListQuery(
      userId: userId,
      types: types,
      pageLogin: pageLogin,
      pageNumber: pageNumber ?? this.pageNumber,
      pageLimit: pageLimit,
      prNumber: prNumber,
      prDate: prDate,
      contractSearch: contractSearch,
    );
  }

  /// Only the search criteria that have a value.
  Map<String, dynamic> get searchData {
    final number = prNumber.trim();
    final date = prDate.trim();
    final contracts = [
      for (final c in contractSearch)
        if (c.trim().isNotEmpty) c.trim(),
    ];
    return {
      if (number.isNotEmpty) 'pr_number': number,
      if (date.isNotEmpty) 'pr_date': date,
      if (contracts.isNotEmpty) 'contract_search': contracts,
    };
  }

  Map<String, dynamic> toJson() => {
        'page_number': '$pageNumber',
        'page_limit': '$pageLimit',
        'search_data': searchData,
        'types': types,
        'page_login': pageLogin,
        'user_id': userId,
      };
}
