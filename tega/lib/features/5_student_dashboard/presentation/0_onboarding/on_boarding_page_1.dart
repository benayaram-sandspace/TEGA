import 'package:flutter/material.dart';
import 'package:tega/features/1_authentication/data/auth_repository.dart';
import 'package:tega/features/5_student_dashboard/presentation/0_onboarding/on_boarding_page_2.dart';

class CareerDiscoveryWelcome extends StatelessWidget {
  final String? studentName;

  const CareerDiscoveryWelcome({super.key, this.studentName});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final firstName = (auth.currentUser?.firstName ?? '').trim();
    final lastName = (auth.currentUser?.lastName ?? '').trim();
    final resolvedName = (studentName?.trim().isNotEmpty == true)
        ? studentName!.trim()
        : (firstName.isNotEmpty
              ? firstName
              : (lastName.isNotEmpty ? lastName : 'there'));

    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700 || size.width < 360;
    final logoSize = isSmall ? 100.0 : 120.0;
    final greetFont = isSmall ? 22.0 : 24.0;
    final bodyFont = isSmall ? 14.0 : 16.0;
    final minorFont = isSmall ? 12.0 : 14.0;

    return WillPopScope(
      onWillPop: () async => false, // 🚫 Prevent back navigation
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height - MediaQuery.of(context).padding.vertical,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: isSmall ? 24 : 40),

                  // TEGA Logo (from assets)
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),

                  SizedBox(height: isSmall ? 6 : 8),

                  // Training and Employment text
                  Text(
                    'TRAINING AND EMPLOYMENT',
                    style: TextStyle(
                      fontSize: isSmall ? 9 : 10,
                      letterSpacing: 1.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'GENERATION ACTIVITIES',
                    style: TextStyle(
                      fontSize: isSmall ? 9 : 10,
                      letterSpacing: 1.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: isSmall ? 24 : 40),

                  // Illustration Image
                  SizedBox(
                    height: size.height * (isSmall ? 0.24 : 0.28),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/illustration.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmall ? 24 : 40),

                  // Greeting text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hi $resolvedName',
                        style: TextStyle(
                          fontSize: greetFont,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('👋', style: TextStyle(fontSize: greetFont)),
                    ],
                  ),

                  SizedBox(height: isSmall ? 14 : 20),

                  // Description text
                  Text(
                    "We're excited to help you discover your",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: bodyFont,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    'future career path using AI.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: bodyFont,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: isSmall ? 18 : 25),

                  // Time and steps info
                  Text(
                    'This will take less than 2 mins. Let\'s find the skills',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: minorFont,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'and jobs that match YOU.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: minorFont,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),

                  SizedBox(height: isSmall ? 20 : 30),

                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 0,
                        child: Text(
                          'Step 1 of 6',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: minorFont,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.17,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 0,
                        child: Text(
                          '17% Complete',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: minorFont,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Start Now Button
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      margin: const EdgeInsets.only(bottom: 30),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingScreen2(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.flash_on, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Start Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
