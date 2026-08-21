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
}