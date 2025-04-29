import 'package:flutter/material.dart';
import 'package:mobile/views/active_inredient/active_ingredient.dart';
import 'package:mobile/views/drug_detection.dart';
import 'package:mobile/views/medicine/medicine_screen.dart';
import 'package:mobile/views/patient/patient_list_page.dart';
import 'package:mobile/views/settings.dart';
import '../constants/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/background-2.jpg'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                // Background Image with Gradient Overlay
                Container(
                  height: MediaQuery.sizeOf(context).height * .4,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/background-2.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Title & Subtitle
                Positioned.fill(
                  top: 60,
                  bottom: 90,
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "TEBEMT",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black45,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "FARMASÖTİK BAKIM ASİSTANI\nETKİN MADDE TESPİTİ",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black45,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Box
                Positioned(
                  bottom: 20,
                  right: 20,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        hintText: "Müstahzar ara...",
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Kısayol Kartları
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildShortcutCard(
                    context,
                    ActiveIngredientScreen(backgroundColor: Theme.of(context).colorScheme.primary),
                    "assets/medicine.png",
                    "Etkin Madde",
                    isNew: true,
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  _buildShortcutCard(
                    context,
                    MedicineScreen(backgroundColor: Theme.of(context).colorScheme.error),
                    "assets/medicine-2.png",
                    "İlaç Tespit",
                    borderColor: Theme.of(context).colorScheme.error,
                  ),
                  _buildShortcutCard(
                    context,
                    PatientListPage(backgroundColor: Colors.green),
                    "assets/communication.png",
                    "Hastalar",
                    borderColor: Colors.green,
                  ),
                  _buildShortcutCard(
                    context,
                    SettingsScreen(backgroundColor: Colors.orange),
                    "assets/settings.png",
                    "Ayarlar",
                    borderColor: Colors.orange,
                  ),
                ],
              ),
            ),

            // Created by Text
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "@ 2024 Mustafa Toprak",
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutCard(
    BuildContext context,
    Widget page,
    String iconPath,
    String label, {
    bool isNew = false,
    Color borderColor = Colors.grey,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
          border: Border.all(color: borderColor.withOpacity(0.2)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      iconPath,
                      height: 30,
                      width: 30,
                      color: borderColor,
                    ),
                  ),
                ),
                if (isNew)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Yeni",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
