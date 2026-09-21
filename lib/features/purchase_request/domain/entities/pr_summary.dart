/// The Summary block of the "Add Purchase Request" form:
///
///   Total Lines            = Σ item.total
///   Administrative Expenses = Total Lines × contract margin %
///   Total Before VAT       = Total Lines + Administrative Expenses
///   VAT                    = 15 % of Total Before VAT
///   Total                  = Total Before VAT + VAT
///
/// Every figure is rounded to 2 decimals at each step, exactly as the
/// reference payload was produced, so the totals shown on screen are the
/// totals sent to the API.
class PrSummary {
  const PrSummary._({
    required this.marginPercent,
    required this.totalLines,
    required this.administrativeExpenses,
    required this.totalBeforeVat,
    required this.vatAmount,
    required this.totalAmount,
  });

  static const double vatRate = 0.15;

  factory PrSummary.calculate({
    required Iterable<double> lineTotals,
    required double marginPercent,
  }) {
    final totalLines = round2(
      lineTotals.fold<double>(0, (sum, total) => sum + round2(total)),
    );
    final administrativeExpenses = round2(totalLines * marginPercent / 100);
    final totalBeforeVat = round2(totalLines + administrativeExpenses);
    final vatAmount = round2(totalBeforeVat * vatRate);
    final totalAmount = round2(totalBeforeVat + vatAmount);

    return PrSummary._(
      marginPercent: marginPercent,
      totalLines: totalLines,
      administrativeExpenses: administrativeExpenses,
      totalBeforeVat: totalBeforeVat,
      vatAmount: vatAmount,
      totalAmount: totalAmount,
    );
  }

  /// The selected contract's margin (%).
  final double marginPercent;
  final double totalLines;
  final double administrativeExpenses;
  final double totalBeforeVat;
  final double vatAmount;
  final double totalAmount;

  /// Rounds to 2 decimals through the exact decimal expansion — the same
  /// result JavaScript's `toFixed(2)` gives (which produced the reference
  /// payload, e.g. VAT 5659.60 on 37730.70).
  static double round2(double value) => double.parse(value.toStringAsFixed(2));
}
