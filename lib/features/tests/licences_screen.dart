import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/features/tests/custom_test_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class LicenceTypesScreen extends StatefulWidget {
  const LicenceTypesScreen({super.key});

  @override
  State<LicenceTypesScreen> createState() => _LicenceTypesScreenState();
}

class _LicenceTypesScreenState extends State<LicenceTypesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> licenseTypes = [];
  List<dynamic> categories = [];
  bool isLoading = false;
  bool isShowingCategories = false;
  bool isShowingTestOptions = false;
  Map<String, dynamic>? selectedLicenseType;
  Map<String, dynamic>? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadLicenseTypes();
  }

  Future<void> _loadLicenseTypes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final licenses = await _apiService.fetchLicenses();
      if (!mounted) return;
      setState(() {
        licenseTypes = licenses;
      });
    } catch (e) {
      _showSnackBar('Error fetching license types: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCategories(String licenceTypeId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedCategories =
          await _apiService.fetchCategories(licenceTypeId);
      if (!mounted) return;
      setState(() {
        categories = fetchedCategories;
        isShowingCategories = true;
      });
    } catch (e) {
      _showSnackBar('Error fetching categories: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onLicenseTypePressed(dynamic licenseType) {
    setState(() {
      selectedLicenseType = licenseType;
    });
    _loadCategories(licenseType['licence_id']);
  }

  void _onCategoryPressed(dynamic category) {
    if (category['is_subscribed'] == false) {
      _showSnackBar('Please buy a subscription to access this category.');
      return;
    }

    setState(() {
      selectedCategory = category;
      isShowingTestOptions = true;
    });
  }

  void _goBack() {
    if (isShowingTestOptions) {
      setState(() {
        isShowingTestOptions = false;
        selectedCategory = null;
      });
    } else if (isShowingCategories) {
      setState(() {
        isShowingCategories = false;
        selectedLicenseType = null;
        categories = [];
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isShowingTestOptions
              ? (selectedCategory?['name'] ?? 'Test Options')
              : isShowingCategories
                  ? (selectedLicenseType?['name'] ?? 'Categories')
                  : 'Licence Types',
        ),
        leading: (isShowingCategories || isShowingTestOptions)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isShowingTestOptions
              ? _buildTestOptionsView()
              : isShowingCategories
                  ? _buildCategoriesView()
                  : _buildLicenseTypesView(),
    );
  }

  Widget _buildLicenseTypesView() {
    return RefreshIndicator(
      onRefresh: _loadLicenseTypes,
      child: ListView.builder(
        itemCount: licenseTypes.length,
        itemBuilder: (context, index) {
          final licenseType = licenseTypes[index];
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () => _onLicenseTypePressed(licenseType),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                licenseType['name'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesView() {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () => _onCategoryPressed(category),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              minimumSize:
                  const Size(double.infinity, 48), // Ensure consistent width
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis, // Handle long text gracefully
                  ),
                  Icon(
                    category['is_subscribed'] == false
                        ? Icons.lock
                        : Icons.lock_open,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestOptionsView() {
    final List<Map<String, dynamic>> testOptions = [
      {
        'label': 'Start Practice Test',
        'onPressed': () async {
          final fetchedQuestions = await _apiService.fetchQuestions(
              selectedLicenseType?['licence_id'],
              selectedCategory?['category_id']);

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Testscreen(
                questions: fetchedQuestions, // List of questions from API
                instantMarking: true, // Enable or disable instant marking
              ),
            ),
          );
        },
      },
      {
        'label': 'Create custom Test',
        'onPressed': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateCustomTestScreen(
                  categoryName: selectedCategory?['name']),
            ),
          );
        },
      },
      {
        'label': 'Saved Questions',
        'onPressed': () {
          _showSnackBar('Saved Questions for ${selectedCategory?['name']}');
        },
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: testOptions.length,
      itemBuilder: (context, index) {
        final option = testOptions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            onPressed: option['onPressed'],
            child: Text(
              option['label'],
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
