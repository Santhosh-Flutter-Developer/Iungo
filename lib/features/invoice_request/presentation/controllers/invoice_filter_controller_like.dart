import 'package:get/get.dart';
import 'package:iungo/features/invoice_request/domain/entities/invoice_request_filter.dart';

/// The subset of [InvoiceDashboardController] that [InvoiceFilterPage]
/// actually needs — mirrors `GrnFilterControllerLike` so the same
/// two-tab ("Filter" / "Find Ticket") screen pattern can later drive a
/// live, API-backed controller too.
abstract class InvoiceFilterControllerLike {
  Rx<InvoiceRequestFilter> get filter;
  Rxn<String> get findNumber;
  List<String> get contractOptions;

  void applyFilter(InvoiceRequestFilter newFilter);
  void clearFilter();
  void findTicket(String number);
}
