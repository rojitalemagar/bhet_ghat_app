import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Namaste, Welcome to BhetGhat!',
      description:
          'Connect with people nearby and build meaningful relationships',
      icon: Icons.people,
    ),
    OnboardingPage(
      title: 'Meet & Chat',
      description: 'Discover new friends and have great conversations',
      icon: Icons.chat_bubble,
    ),
    OnboardingPage(
      title: 'Share & Enjoy',
      description: 'Plan events and create memories together',
      icon: Icons.celebration,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final padding = isMobile ? 20.0 : 40.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade300,
              Colors.deepPurple.shade600,
              Colors.purple.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: padding * 0.5),
              Image.asset(
                'assets/images/bhetghat_logo.png',
                width: isMobile ? 80 : 120,
                height: isMobile ? 80 : 120,
                fit: BoxFit.contain,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return OnboardingPageView(
                      page: pages[index],
                      isMobile: isMobile,
                      padding: padding,
                    );
                  },
                ),
              ),
              SizedBox(
                width: 240,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        width: _currentPage == index ? 24 : 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_currentPage > 0)
                TextButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                const SizedBox(height: 36),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 8, padding, padding),
          child: SizedBox(
            width: double.infinity,
            height: isMobile ? 48 : 56,
            child: ElevatedButton(
              onPressed: _currentPage == pages.length - 1
                  ? () => Navigator.pushReplacementNamed(context, '/login')
                  : () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;
  final bool isMobile;
  final double padding;

  const OnboardingPageView({
    super.key,
    required this.page,
    required this.isMobile,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isMobile ? 100 : 150,
            height: isMobile ? 100 : 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              page.icon,
              size: isMobile ? 60 : 90,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isMobile ? 40 : 60),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 30),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
