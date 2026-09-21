/// The `filter_options` block of the Purchase Request list response.
class PrFilterOptions {
  const PrFilterOptions({
    this.createdBy = const [],
    this.status = const [],
    this.contracts = const [],
  });

  final List<String> createdBy;
  final List<String> status;
  final List<String> contracts;

  static const PrFilterOptions empty = PrFilterOptions();
}
