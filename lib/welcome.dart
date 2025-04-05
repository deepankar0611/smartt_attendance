import 'package:flutter/material.dart';
import 'package:smartt_attendance/student%20screen/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Professional color scheme with better contrast
  final Color _primaryColor = const Color(0xFF034A29);  // Indigo 600
  final Color _accentColor = const Color(0xFF9FA8DA);   // Indigo 200
  final Color _textPrimaryColor = const Color(0xFF212121);
  final Color _textSecondaryColor = const Color(0xFF757575);

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "Track Attendance Easily",
      quote: "Simplify attendance tracking with our smart, contactless solution.",
      image: "assets/S1.jpg",
    ),
    OnboardingContent(
      title: "Real-time Analytics",
      quote: "Get instant insights on attendance patterns and student engagement.",
      image: "assets/S2.jpg",
    ),
    OnboardingContent(
      title: "Stay Connected",
      quote: "Automated notifications keep everyone informed and accountable.",
      image: "assets/S3.jpg",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return buildOnboardingPage(_contents[index]);
                },
              ),
            ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Page indicators
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _contents.length,
                            (index) => buildDot(index),
                      ),
                    ),
                  ),

                  // Navigation buttons - made smaller
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back button (hidden on first page)
                      if (_currentPage != 0)
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          height: 40,
                          width: 100,
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(color: _primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              "Back",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      // Next/Get Started button
                      SizedBox(
                        height: 40,
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                            if (_currentPage == _contents.length - 1) {
                              // Navigate to login/register screen
                              print("Get Started Pressed - Navigate to Login");
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            _currentPage == _contents.length - 1 ? "Get Started" : "Next",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOnboardingPage(OnboardingContent content) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image with shadow and contrast accent border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: _accentColor,
                  width: 4,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  content.image,
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Title with primary color
            Text(
              content.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              content.quote,
              style: TextStyle(
                fontSize: 16,
                color: _textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? _primaryColor : _accentColor,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String quote;
  final String image;

  OnboardingContent({
    required this.title,
    required this.quote,
    required this.image,
  });
}