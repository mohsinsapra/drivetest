bool hasResumableProgressChanges({
  required Map<int, String> initialSelections,
  required Map<int, String> currentSelections,
  required int initialQuestionIndex,
  required int currentQuestionIndex,
}) {
  if (currentQuestionIndex != initialQuestionIndex) {
    return true;
  }

  if (currentSelections.length != initialSelections.length) {
    return true;
  }

  for (final entry in currentSelections.entries) {
    if (initialSelections[entry.key] != entry.value) {
      return true;
    }
  }

  return false;
}
