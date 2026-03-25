import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';
import 'package:sajilo_ride/utils/text_styles.dart';


class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 650;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: isDesktop ?  AssetImage("assets/images/onboarding_bg.png") :
            AssetImage("assets/images/onboarding_bg(mobile).png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'SAJILO YATRA',
                    style: AppTextStyles.headingWhiteLogo,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Row(
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text('Home',
                          style: isDesktop ? AppTextStyles.smallTextWhite : const TextStyle(color: Colors.white, fontSize: 10)),
                    ),

                    if (isDesktop) ...[
                      TextButton(
                        onPressed: () {},
                        child: const Text('About', style: AppTextStyles.smallTextWhite),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Contact', style: AppTextStyles.smallTextWhite),
                      ),
                    ]
                  ],
                ),
              ],
            ),

            const Spacer(),

            // --- BOTTOM BUTTON ---
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Get Started",
                  style: AppTextStyles.bodyTextWhite,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
