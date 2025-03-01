import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final Color backgroundColor;

  const SettingsScreen({super.key, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor.withAlpha(200),
        title: const Text("Ayarlar"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            ProfilePic(backgroundColor: backgroundColor),
            const SizedBox(height: 20),
            ProfileMenu(
              text: "Profile",
              icon: Icons.person,
              backgroundColor: backgroundColor,
              press: () => {},
            ),
            ProfileMenu(
              text: "Bildirimler",
              icon: Icons.notifications,
              backgroundColor: backgroundColor,
              press: () {},
            ),
            ProfileMenu(
              text: "Yardım Merkezi",
              icon: Icons.help_center,
              backgroundColor: backgroundColor,
              press: () {},
            ),
            ProfileMenu(
              text: "Çıkış Yap",
              icon: Icons.logout,
              backgroundColor: Colors.red,
              press: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  final Color backgroundColor;

  const ProfilePic({super.key, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 115,
      width: 115,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          const CircleAvatar(
            backgroundImage: NetworkImage(
                "https://cdn-icons-png.flaticon.com/512/219/219970.png"),
          ),
          Positioned(
            right: -16,
            bottom: 0,
            child: SizedBox(
              height: 46,
              width: 46,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFF5F6F9),
                ),
                onPressed: () {},
                child: Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: backgroundColor,
                ), // Kamera ikonu
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.text,
    required this.icon,
    required this.backgroundColor,
    this.press,
  });

  final String text;
  final IconData icon; // IconData olarak değiştirdik
  final VoidCallback? press;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: backgroundColor,
          padding: const EdgeInsets.all(20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: const Color(0xFFF5F6F9),
        ),
        onPressed: press,
        child: Row(
          children: [
            Icon(
              icon, // Icon widget'ı burada kullanıldı
              color: backgroundColor,
              size: 22,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF757575),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF757575),
            ),
          ],
        ),
      ),
    );
  }
}
