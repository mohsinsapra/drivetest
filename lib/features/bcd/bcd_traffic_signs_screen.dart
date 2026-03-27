import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'bcd_text_utils.dart';

// ── List screen ────────────────────────────────────────────────────────────────

class BCDTrafficSignsScreen extends StatefulWidget {
  const BCDTrafficSignsScreen({super.key});

  @override
  State<BCDTrafficSignsScreen> createState() => _BCDTrafficSignsScreenState();
}

class _BCDTrafficSignsScreenState extends State<BCDTrafficSignsScreen> {
  final _api = ApiService();
  final _scrollController = ScrollController();
  List<dynamic> _signs = [];
  bool _loading = true;
  String _search = '';
  Timer? _refreshTimer;

  static const _autoRefreshInterval = Duration(hours: 1);

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _signs;
    final q = _search.toLowerCase();
    return _signs.where((s) {
      final title = (s['title'] ?? '').toString().toLowerCase();
      final content = (s['content'] ?? '').toString().toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer =
        Timer.periodic(_autoRefreshInterval, (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.fetchBCDTrafficSigns();
      if (mounted) {
        setState(() {
          _signs = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showAppSnackBar('Failed to load traffic signs');
      }
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final data = await _api.fetchBCDTrafficSigns();
      if (mounted) setState(() => _signs = data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Traffic Signs'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search sign groups…',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFF5F5F7),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const _Shimmer()
                : _filtered.isEmpty
                    ? ListView(children: [
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: Text('No signs found',
                                style:
                                    TextStyle(color: Colors.grey.shade500)),
                          ),
                        ),
                      ])
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _SignGroupCard(
                            sign: _filtered[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _SignGroupDetailScreen(
                                  group: _filtered[i],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Group card ─────────────────────────────────────────────────────────────────

class _SignGroupCard extends StatelessWidget {
  final dynamic sign;
  final VoidCallback onTap;
  const _SignGroupCard({required this.sign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = cleanBcdText(sign['title']?.toString() ?? '');
    final content = cleanBcdText(sign['content']?.toString() ?? '');
    final images = (sign['images'] as List<dynamic>? ?? []);
    final children = (sign['children'] as List<dynamic>? ?? []);
    final signCount =
        children.isNotEmpty ? children.length : images.length;

    // Collect up to 3 preview image URLs
    final previewUrls = <String>[];
    for (final img in images.take(3)) {
      final fn = img['file_name']?.toString() ?? '';
      if (fn.isNotEmpty) previewUrls.add(ApiService().bcdMediaUrl(fn));
    }
    if (previewUrls.isEmpty) {
      for (final child in children.take(3)) {
        final childImgs = (child['images'] as List<dynamic>? ?? []);
        if (childImgs.isNotEmpty) {
          final fn = childImgs.first['file_name']?.toString() ?? '';
          if (fn.isNotEmpty) previewUrls.add(ApiService().bcdMediaUrl(fn));
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image collage area
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 170,
                width: double.infinity,
                color: const Color(0xFFF8F8FA),
                child: previewUrls.isEmpty
                    ? Center(
                        child: Icon(LucideIcons.alertTriangle,
                            size: 60, color: Colors.grey.shade300))
                    : _ImageCollage(urls: previewUrls),
              ),
            ),
            // Divider
            Divider(height: 1, color: Colors.grey.shade100),
            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF111827))),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      content.length > 110
                          ? '${content.substring(0, 110)}…'
                          : content,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.45),
                    ),
                  ],
                  if (signCount > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(LucideIcons.alertTriangle,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text('$signCount traffic signs',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF3B5BDB),
                                      fontWeight: FontWeight.w600)),
                              SizedBox(width: 3),
                              Icon(LucideIcons.chevronRight,
                                  size: 13, color: Color(0xFF3B5BDB)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Overlapping image collage
class _ImageCollage extends StatelessWidget {
  final List<String> urls;
  const _ImageCollage({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _NetImg(url: urls[0], size: 120),
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: 220,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (urls.length >= 3)
              Positioned(
                  left: 0,
                  bottom: 16,
                  child: _NetImg(url: urls[2], size: 78, opacity: 0.80)),
            if (urls.length >= 2)
              Positioned(
                  right: 0,
                  top: 12,
                  child: _NetImg(url: urls[1], size: 90)),
            Positioned(
                left: 40,
                top: 16,
                child: _NetImg(url: urls[0], size: 108)),
          ],
        ),
      ),
    );
  }
}

class _NetImg extends StatelessWidget {
  final String url;
  final double size;
  final double opacity;
  const _NetImg({required this.url, required this.size, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(LucideIcons.image,
            size: size * 0.4, color: Colors.grey.shade300),
      ),
    );
  }
}

// ── Detail screen ──────────────────────────────────────────────────────────────

class _SignGroupDetailScreen extends StatefulWidget {
  final dynamic group;
  const _SignGroupDetailScreen({required this.group});

  @override
  State<_SignGroupDetailScreen> createState() => _SignGroupDetailScreenState();
}

class _SignGroupDetailScreenState extends State<_SignGroupDetailScreen> {
  late final List<dynamic> _slides;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final children = (widget.group['children'] as List<dynamic>? ?? []);
    _slides = children.isNotEmpty ? children : [widget.group];
  }

  int get _total => _slides.length;
  dynamic get _current => _slides[_index];

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  void _next() {
    if (_index < _total - 1) setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final groupTitle =
        cleanBcdText(widget.group['title']?.toString() ?? '');
    final title = cleanBcdText(_current['title']?.toString() ?? '');
    final content = cleanBcdText(_current['content']?.toString() ?? '');
    final images = (_current['images'] as List<dynamic>? ?? []);

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null) {
          if (d.primaryVelocity! < -200) _next();
          if (d.primaryVelocity! > 200) _prev();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(groupTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              if (_total > 1)
                Text('${_index + 1} / $_total',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Progress bar
            if (_total > 1)
              LinearProgressIndicator(
                value: (_index + 1) / _total,
                minHeight: 2,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF3B5BDB),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sign code / title card
                    if (title.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF111827))),
                      ),
                    const SizedBox(height: 12),
                    // Image viewer card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _NavArrow(
                            icon: LucideIcons.chevronLeft,
                            enabled: _index > 0,
                            onTap: _prev,
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 230,
                              child: images.isEmpty
                                  ? Center(
                                      child: Icon(
                                          LucideIcons.alertTriangle,
                                          size: 64,
                                          color: Colors.grey.shade300))
                                  : _SignImageViewer(images: images),
                            ),
                          ),
                          _NavArrow(
                            icon: LucideIcons.chevronRight,
                            enabled: _index < _total - 1,
                            onTap: _next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Description card
                    if (content.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(content,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                height: 1.6)),
                      ),
                    const SizedBox(height: 24),
                    // Prev / Next buttons at bottom
                    if (_total > 1)
                      Row(
                        children: [
                          Expanded(
                            child: _BottomNavButton(
                              label: 'Previous',
                              icon: LucideIcons.chevronLeft,
                              enabled: _index > 0,
                              onTap: _prev,
                              isLeading: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BottomNavButton(
                              label: 'Next',
                              icon: LucideIcons.chevronRight,
                              enabled: _index < _total - 1,
                              onTap: _next,
                              isLeading: false,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavArrow(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        child: Icon(icon,
            size: 22,
            color: enabled
                ? Colors.grey.shade600
                : Colors.grey.shade200),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool isLeading;
  const _BottomNavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.isLeading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: enabled
                  ? Colors.grey.shade300
                  : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isLeading
              ? [
                  Icon(icon,
                      size: 16,
                      color: enabled
                          ? Colors.grey.shade700
                          : Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? Colors.grey.shade700
                              : Colors.grey.shade400)),
                ]
              : [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? const Color(0xFF3B5BDB)
                              : Colors.grey.shade400)),
                  const SizedBox(width: 6),
                  Icon(icon,
                      size: 16,
                      color: enabled
                          ? const Color(0xFF3B5BDB)
                          : Colors.grey.shade400),
                ],
        ),
      ),
    );
  }
}

class _SignImageViewer extends StatelessWidget {
  final List<dynamic> images;
  const _SignImageViewer({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      final url = ApiService()
          .bcdMediaUrl(images[0]['file_name']?.toString() ?? '');
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Image.network(url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(LucideIcons.image,
                size: 48, color: Colors.grey.shade300)),
      );
    }
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (_, i) {
        final url = ApiService()
            .bcdMediaUrl(images[i]['file_name']?.toString() ?? '');
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Image.network(url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(LucideIcons.image,
                  size: 48, color: Colors.grey.shade300)),
        );
      },
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
