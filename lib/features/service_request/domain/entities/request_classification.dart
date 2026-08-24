/// Classification options shown in the "New Service Request" form dropdown.
enum RequestClassification { question, problem, feature }

extension RequestClassificationX on RequestClassification {
  String get labelKey {
    switch (this) {
      case RequestClassification.question:
        return 'classification_question';
      case RequestClassification.problem:
        return 'classification_problem';
      case RequestClassification.feature:
        return 'classification_feature';
    }
  }

  /// Numeric key the server expects for `classificationType` — from the
  /// form definition's inline enumMap: `{"1":"Question","2":"Problem",
  /// "3":"Feature"}` (confirmed via the form-fields API response).
  int get apiValue {
    switch (this) {
      case RequestClassification.question:
        return 1;
      case RequestClassification.problem:
        return 2;
      case RequestClassification.feature:
        return 3;
    }
  }

  /// Reverse of [apiValue] — used when reading `classificationType` back
  /// off the Detail View API response. Defaults to [problem] for an
  /// unrecognized/missing value, matching the rest of this app's
  /// fallback convention rather than throwing on unexpected server data.
  static RequestClassification fromApiValue(int? value) {
    switch (value) {
      case 1:
        return RequestClassification.question;
      case 3:
        return RequestClassification.feature;
      case 2:
      default:
        return RequestClassification.problem;
    }
  }
}