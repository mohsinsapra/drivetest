// lib/core/router/route_names.dart

abstract class Routes {
  static const splash       = '/splash';
  static const intro        = '/intro';
  static const auth         = '/auth';
  static const authForgot   = '/auth/forgot';
  static const authVerify   = '/auth/verify';
  static const authReset    = '/auth/reset';

  // Shell branches
  static const home         = '/home';
  static const tests        = '/tests';
  static const bcd          = '/bcd';
  static const profile      = '/profile';

  // Profile stack
  static const profileEdit  = '/profile/edit';
  static const profileStats = '/profile/stats';
  static const settings     = '/settings';
  static const help         = '/help';

  // Home stack
  static const attempt      = '/attempt/:attemptId';
  static String attemptPath(String id) => '/attempt/$id';

  // Test stack (extra-only — no reload support for in-progress tests)
  static const test         = '/test';
  static const result       = '/result';
  static const testsCustom  = '/tests/custom';
  static const testsSaved   = '/tests/saved';

  // BCD stack
  static const bcdLicences      = '/bcd/licences';
  static const bcdSigns         = '/bcd/signs';
  static const bcdSubscriptions = '/bcd/subscriptions';
  static const bcdCategory      = '/bcd/category/:id';
  static String bcdCategoryPath(String id) => '/bcd/category/$id';
  static const bcdSubcategory   = '/bcd/subcategory/:id';
  static String bcdSubcategoryPath(String id) => '/bcd/subcategory/$id';
  static const bcdTest          = '/bcd/test';
  static const bcdDoc           = '/bcd/doc';
}
