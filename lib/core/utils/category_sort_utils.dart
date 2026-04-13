List<dynamic> sortSubscribedCategoriesFirst(List<dynamic> categories) {
  final sorted = List<dynamic>.from(categories);
  sorted.sort((a, b) {
    final aSubscribed = a['is_subscribed'] == true;
    final bSubscribed = b['is_subscribed'] == true;
    if (aSubscribed != bSubscribed) {
      return aSubscribed ? -1 : 1;
    }
    final aName = a['name']?.toString().toLowerCase() ?? '';
    final bName = b['name']?.toString().toLowerCase() ?? '';
    return aName.compareTo(bName);
  });
  return sorted;
}
