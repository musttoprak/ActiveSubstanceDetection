import 'package:flutter/material.dart';
import 'package:mobile/views/active_ingredient.dart';
import 'package:mobile/views/drug_detection.dart';
import 'package:mobile/views/patient/patient_list_page.dart';
import 'package:mobile/views/settings.dart';
import '../constants/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: MediaQuery.sizeOf(context).height * .4,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/background-2.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 90,
                  left: 50,
                  right: 50,
                  bottom: 90,
                  child: Column(
                    children: [
                      Text(
                        "TEBEMT",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryAccent,
                        ),
                      ),
                      Text(
                        "FARMASÖTİK BAKIM ASİSTANI - ETKİN MADDE TESPİİTİ",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 5,
                  left: 5,
                  child: TextField(
                    decoration: InputDecoration(
                      constraints: BoxConstraints(maxHeight: 50, minHeight: 50),
                      hintText: "Müstahzar ara!",
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.secondaryAccent, size: 24),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.secondaryAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.secondaryAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.secondaryAccent),
                      ),
                    ),
                  ),
                )
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
                    ActiveIngredientScreen(backgroundColor: Colors.blue),
                    "assets/medicine.png",
                    "Etkin Madde",
                    isNew: true,
                    borderColor: Colors.blue,
                  ),
                  _buildShortcutCard(
                    context,
                    DrugDetectionScreen(backgroundColor: Colors.red),
                    "assets/medicine-2.png",
                    "İlaç Tespit",
                    borderColor: Colors.red,
                  ),
                  _buildShortcutCard(
                    context,
                    PatientListPage(),
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
                  color: AppColors.headerTextColor,
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
        // Yeni pencereyi aç
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      iconPath,
                      fit: BoxFit.contain,
                      height: 40,
                      width: 40,
                      color: borderColor,
                    ),
                  ),
                ),
              ),
              if (isNew)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "Yeni",
                      style: TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
