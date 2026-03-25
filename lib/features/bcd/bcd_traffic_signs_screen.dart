import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'bcd_text_utils.dart';

class BCDTrafficSignsScreen extends StatefulWidget {
  const BCDTrafficSignsScreen({super.key});

  @override
  State<BCDTrafficSignsScreen> createState() => _BCDTrafficSignsScreenState();
}

class _BCDTrafficSignsScreenState extends State<BCDTrafficSignsScreen> {
  final _api = ApiService();
  List<dynamic> _signs = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.fetchBCDTrafficSigns();
      if (mounted) setState(() { _signs = data; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showAppSnackBar('Failed to load traffic signs'); }
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traffic Signs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search signs…',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Colors.grey.shade100,
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
                ? _Shimmer()
                : _filtered.isEmpty
                    ? Center(
                        child: Text('No signs found',
                            style: TextStyle(color: Colors.grey.shade500)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) =>
                              _SignGroup(sign: _filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SignGroup extends StatelessWidget {
  final dynamic sign;
  const _SignGroup({required this.sign});

  @override
  Widget build(BuildContext context) {
    final children = (sign['children'] as List<dynamic>? ?? []);
    final images = (sign['images'] as List<dynamic>? ?? []);
    final title = cleanBcdText(sign['title']?.toString() ?? '');
    final content = cleanBcdText(sign['content']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.alertTriangle,
              color: Color(0xFFD97706), size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: content.isNotEmpty
            ? Text(
                content.length > 60
                    ? '${content.substring(0, 60)}…'
                    : content,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600),
              )
            : null,
        children: [
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: images.map<Widget>((img) => _SignImage(img)).toList(),
              ),
            ),
          if (content.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(content,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
            ),
          ...children.map<Widget>((child) => _ChildSign(sign: child)),
        ],
      ),
    );
  }
}

class _ChildSign extends StatelessWidget {
  final dynamic sign;
  const _ChildSign({required this.sign});

  @override
  Widget build(BuildContext context) {
    final images = (sign['images'] as List<dynamic>? ?? []);
    final title = cleanBcdText(sign['title']?.toString() ?? '');
    final content = cleanBcdText(sign['content']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: images.map<Widget>((img) => _SignImage(img)).toList(),
              ),
            ),
          if (title.isNotEmpty)
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(content,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _SignImage extends StatelessWidget {
  final dynamic img;
  const _SignImage(this.img);

  @override
  Widget build(BuildContext context) {
    final fileName = img['file_name']?.toString() ?? '';
    if (fileName.isEmpty) return const SizedBox.shrink();

    final url = ApiService().bcdMediaUrl(fileName);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 64,
          height: 64,
          color: Colors.grey.shade100,
          child: const Icon(LucideIcons.image,
              color: Colors.grey, size: 24),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
