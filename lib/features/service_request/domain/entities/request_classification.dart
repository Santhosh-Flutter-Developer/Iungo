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
}
