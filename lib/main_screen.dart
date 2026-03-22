import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/features/home/home_screen.dart';
import 'package:taxi_exam_app/features/tests/licences_screen.dart';
import 'package:taxi_exam_app/features/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late PageController _pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LicenceTypesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MainScreenProvider>(context, listen: false);
    provider.setIndex(0);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for index changes and animate the page view
    Provider.of<MainScreenProvider>(context).addListener(() {
      if (!mounted) return;
      final index =
          Provider.of<MainScreenProvider>(context, listen: false).currentIndex;
      _pageController.jumpToPage(index); // or use animateToPage
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    Provider.of<MainScreenProvider>(context, listen: false).setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MainScreenProvider>(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,

        physics: const ClampingScrollPhysics(),
        children: _screens, // Prevent overscroll glow
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: provider.currentIndex,
          onTap: (index) => provider.setIndex(index),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bookOpenCheck),
              label: 'Tests',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreenProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
