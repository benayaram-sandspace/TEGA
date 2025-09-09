import 'package:flutter/material.dart';

class CareerDiscoveryWelcome extends StatelessWidget {
  final String studentName;

  const CareerDiscoveryWelcome({Key? key, this.studentName = 'Ramesh'})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // TEGA Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFFFD700), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Person icon with fork and spoon
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFF2E7D32),
                        ),
                        Positioned(
                          left: 20,
                          child: Transform.rotate(
                            angle: -0.3,
                            child: const Icon(
                              Icons.restaurant,
                              size: 20,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          child: Transform.rotate(
                            angle: 0.3,
                            child: const Icon(
                              Icons.restaurant,
                              size: 20,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'TEGA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Training and Employment text
              const Text(
                'TRAINING AND EMPLOYMENT',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Text(
                'GENERATION ACTIVITIES',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              // Illustration Card
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFB74D).withOpacity(0.8),
                      const Color(0xFFFFCC80),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: 20,
                      right: 80,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 30,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784).withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 40,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Telegram icon in corner
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    // Person with laptop illustration
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Row(
                        children: [
                          // Simple person illustration
                          Container(
                            width: 80,
                            height: 100,
                            child: CustomPaint(
                              painter: PersonWithLaptopPainter(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Chat/document bubbles
                          Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.orange,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: 50,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE8F5E9,
                                  ).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: Colors.green,
                                  size: 20,
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

              const SizedBox(height: 40),

              // Greeting text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hi $studentName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ],
              ),

              const SizedBox(height: 20),

              // Description text
              const Text(
                "We're excited to help you discover your",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const Text(
                'future career path using AI.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 25),

              // Time and steps info
              const Text(
                'This will take less than 2 mins. Let\'s find the skills',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const Text(
                'and jobs that match YOU.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Step 1 of 6',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.17,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA726),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    '17% Complete',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Start Now Button
              Container(
                width: double.infinity,
                height: 55,
                margin: const EdgeInsets.only(bottom: 30),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to next screen
                    // Navigator.push(context, MaterialPageRoute(
                    //   builder: (context) => NextScreen(),
                    // ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726),
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
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for person with laptop illustration
class PersonWithLaptopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Head
    paint.color = const Color(0xFF2C3E50);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.25), 15, paint);

    // Hair
    paint.color = const Color(0xFF1A237E);
    final hairPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.1,
        size.width * 0.65,
        size.height * 0.25,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.3,
        size.width * 0.35,
        size.height * 0.3,
      )
      ..close();
    canvas.drawPath(hairPath, paint);

    // Body
    paint.color = const Color(0xFF2196F3);
    final bodyPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.4)
      ..lineTo(size.width * 0.75, size.height * 0.75)
      ..lineTo(size.width * 0.25, size.height * 0.75)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Laptop
    paint.color = Colors.grey.shade700;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.7,
        size.width * 0.6,
        size.height * 0.2,
      ),
      paint,
    );

    // Laptop screen
    paint.color = Colors.grey.shade300;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.73,
        size.width * 0.5,
        size.height * 0.14,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
