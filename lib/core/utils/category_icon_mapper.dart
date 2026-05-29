import 'package:flutter/material.dart';

/// Returns a semantically relevant icon for a BCD/exam category based on its name.
///
/// Rules are ordered from most specific to most generic so that e.g.
/// "Lastbil med släp" beats the generic "lastbil" rule.
IconData categoryIcon(String name) {
  final s = name.toLowerCase();

  // ── Specific Swedish driving-exam categories (exact product names) ──────────

  // YKB — Yrkeskompetensbevis (professional driver certificate) — checked FIRST
  // so "YKB Buss" and "YKB lastbil" get the certificate icon, not vehicle icons.
  if (_has(s, ['ykb'])) {
    return Icons.workspace_premium_rounded;
  }
  // B-körkort (car licence — B category)
  if (_has(s, ['b-körkort', 'b körkort', 'bkörkort'])) {
    return Icons.directions_car_rounded;
  }
  // Motorcykel
  if (_has(s, ['motorcykel', 'motorcycle', 'moped', 'mc '])) {
    return Icons.two_wheeler_rounded;
  }
  // Lastbil med släp (truck + trailer)
  if (_has(s, ['med släp', 'släp', 'trailer'])) {
    return Icons.rv_hookup_rounded;
  }
  // Lastbil / truck (generic)
  if (_has(s, ['lastbil', 'truck', 'lorry'])) {
    return Icons.local_shipping_rounded;
  }
  // Buss / bus
  if (_has(s, ['buss', 'bus '])) {
    return Icons.directions_bus_rounded;
  }
  // Gods åkeri (freight/goods haulage)
  if (_has(s, ['gods', 'frakt', 'cargo', 'freight', 'godstransport'])) {
    return Icons.inventory_2_rounded;
  }
  // Taxiförarlegitimation (taxi driver ID/licence)
  if (_has(s, ['legitimation', 'taxiförare', 'taxiförar'])) {
    return Icons.badge_rounded;
  }
  // Taxi åkeri / taxi haulage
  if (_has(s, ['taxi'])) {
    return Icons.local_taxi_rounded;
  }
  // Vägmärkestest (traffic signs exam)
  if (_has(s, ['vägmärk', 'vägmärkes'])) {
    return Icons.traffic_rounded;
  }
  // Generic test / practice
  if (_has(s, ['test', 'prov', 'quiz', 'practice', 'övning'])) {
    return Icons.quiz_rounded;
  }

  // ── Generic topic keywords ──────────────────────────────────────────────────

  if (_has(s, ['lag', 'rule', 'regel', 'legal', 'bestämmelse', 'föreskrift'])) {
    return Icons.gavel_rounded;
  }
  if (_has(s, ['skylt', 'sign', 'signal', 'märk'])) {
    return Icons.traffic_rounded;
  }
  if (_has(s, ['säker', 'safety', 'skydd', 'protect', 'trygg'])) {
    return Icons.health_and_safety_rounded;
  }
  if (_has(s, ['fordon', 'vehicle', 'motor', 'däck', 'tyre', 'mekanik'])) {
    return Icons.directions_car_rounded;
  }
  if (_has(s, ['hastighet', 'speed', 'fart'])) {
    return Icons.speed_rounded;
  }
  if (_has(s, ['körning', 'driv', 'manöver'])) {
    return Icons.roundabout_right_rounded;
  }
  if (_has(s, ['trafik', 'traffic', 'korsning', 'intersection'])) {
    return Icons.fork_right_rounded;
  }
  if (_has(s, ['alkohol', 'drog', 'drug', 'berus', 'narkotika'])) {
    return Icons.no_drinks_rounded;
  }
  if (_has(s,
      ['dokument', 'document', 'handling', 'körkort', 'licens', 'licence'])) {
    return Icons.badge_rounded;
  }
  if (_has(s, ['olycka', 'accident', 'krock', 'crash', 'skada'])) {
    return Icons.emergency_rounded;
  }
  if (_has(s, ['miljö', 'environment', 'klimat', 'utsläpp', 'eco'])) {
    return Icons.eco_rounded;
  }
  if (_has(s, ['ansvar', 'responsibility', 'försäkring', 'insurance'])) {
    return Icons.account_balance_rounded;
  }
  if (_has(s, ['ekonomi', 'economy', 'kostn', 'avgift', 'bränsle', 'fuel'])) {
    return Icons.payments_rounded;
  }
  if (_has(s, ['hälsa', 'health', 'medicin', 'trötthet', 'fatigue'])) {
    return Icons.medical_services_rounded;
  }
  if (_has(s, ['parkering', 'stopp', 'stanna'])) {
    return Icons.local_parking_rounded;
  }
  if (_has(s, ['transport', 'åkeri'])) {
    return Icons.local_shipping_rounded;
  }
  if (_has(
      s, ['natt', 'night', 'mörker', 'dimma', 'fog', 'väder', 'weather'])) {
    return Icons.nights_stay_rounded;
  }

  return Icons.library_books_rounded;
}

/// Returns a semantically relevant accent color for a BCD/exam category.
Color categoryColor(String name) {
  final s = name.toLowerCase();

  // ── Specific Swedish driving-exam categories ────────────────────────────────

  // YKB first so "YKB Buss" / "YKB lastbil" get the certification color
  if (_has(s, ['ykb'])) {
    return const Color(0xFF059669); // green — professional certification
  }
  if (_has(s, ['b-körkort', 'b körkort', 'bkörkort'])) {
    return const Color(0xFF4F46E5); // indigo — standard car licence
  }
  if (_has(s, ['motorcykel', 'motorcycle', 'moped', 'mc '])) {
    return const Color(0xFFEA580C); // orange — motorbike energy
  }
  if (_has(s, ['med släp', 'släp', 'trailer'])) {
    return const Color(0xFF1E40AF); // dark blue — heavy vehicle + trailer
  }
  if (_has(s, ['lastbil', 'truck', 'lorry'])) {
    return const Color(0xFF1D4ED8); // blue — heavy vehicle
  }
  if (_has(s, ['buss', 'bus '])) {
    return const Color(0xFF0D9488); // teal — public transport
  }
  if (_has(s, ['gods', 'frakt', 'cargo', 'freight', 'godstransport'])) {
    return const Color(0xFFB45309); // amber-brown — freight
  }
  if (_has(s, ['legitimation', 'taxiförar'])) {
    return const Color(0xFF7C3AED); // purple — official ID/credential
  }
  if (_has(s, ['taxi'])) {
    return const Color(0xFFD97706); // amber — taxi yellow
  }
  if (_has(s, ['vägmärk', 'vägmärkes'])) {
    return const Color(0xFFD97706); // amber — warning/road signs
  }
  if (_has(s, ['test', 'prov', 'quiz', 'practice', 'övning'])) {
    return const Color(0xFF2563EB); // blue — neutral exam
  }

  // ── Generic topic keywords ──────────────────────────────────────────────────

  if (_has(s, ['lag', 'rule', 'regel', 'legal', 'bestämmelse'])) {
    return const Color(0xFF1976D2);
  }
  if (_has(s, ['skylt', 'sign', 'signal', 'märk'])) {
    return const Color(0xFFD97706);
  }
  if (_has(s, ['säker', 'safety', 'skydd', 'protect', 'trygg'])) {
    return const Color(0xFF059669);
  }
  if (_has(s, ['fordon', 'vehicle', 'motor', 'däck', 'mekanik'])) {
    return const Color(0xFF0891B2);
  }
  if (_has(s, ['hastighet', 'speed', 'fart'])) {
    return const Color(0xFFB45309);
  }
  if (_has(s, ['körning', 'driv', 'manöver'])) {
    return const Color(0xFF4F46E5);
  }
  if (_has(s, ['trafik', 'traffic', 'korsning'])) {
    return const Color(0xFF0284C7);
  }
  if (_has(s, ['alkohol', 'drog', 'drug', 'berus', 'narkotika'])) {
    return const Color(0xFFDC2626);
  }
  if (_has(s, ['dokument', 'document', 'handling', 'körkort', 'licens'])) {
    return const Color(0xFF7C3AED);
  }
  if (_has(s, ['olycka', 'accident', 'krock', 'crash', 'skada'])) {
    return const Color(0xFFEA580C);
  }
  if (_has(s, ['miljö', 'environment', 'klimat', 'utsläpp', 'eco'])) {
    return const Color(0xFF16A34A);
  }
  if (_has(s, ['ansvar', 'responsibility', 'försäkring', 'insurance'])) {
    return const Color(0xFF7C3AED);
  }
  if (_has(s, ['ekonomi', 'economy', 'kostn', 'avgift', 'bränsle'])) {
    return const Color(0xFFB45309);
  }
  if (_has(s, ['hälsa', 'health', 'medicin', 'trötthet'])) {
    return const Color(0xFFE11D48);
  }
  if (_has(s, ['parkering', 'stopp'])) {
    return const Color(0xFF6D28D9);
  }
  if (_has(s, ['transport', 'åkeri'])) {
    return const Color(0xFF00897B);
  }
  if (_has(s, ['natt', 'night', 'mörker', 'dimma', 'fog', 'väder'])) {
    return const Color(0xFF475569);
  }

  // Fallback — cycle by hash so unknown categories still vary
  const fallbacks = [
    Color(0xFF1976D2),
    Color(0xFFF9A825),
    Color(0xFFE65100),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
  ];
  return fallbacks[name.hashCode.abs() % fallbacks.length];
}

/// Solid background color for the text panel of an image card.
/// Matched to the dominant background of each illustration.
bool _has(String text, List<String> keywords) =>
    keywords.any((kw) => text.contains(kw));

/// Adds a localised prefix when a node name is bare (only digits or letters,
/// e.g. "1", "A", "12", "AB").  Meaningful names pass through unchanged.
/// Pass the translated prefix from the call site via [groupPrefix].
String formatNodeName(String name, String groupPrefix) {
  final trimmed = name.trim();
  if (RegExp(r'^[A-Za-z0-9]+$').hasMatch(trimmed)) {
    return '$groupPrefix $trimmed';
  }
  return trimmed;
}
