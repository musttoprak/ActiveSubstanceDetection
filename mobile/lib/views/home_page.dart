import 'package:flutter/material.dart';
import 'package:mobile/views/active_inredient/active_ingredient.dart';
import 'package:mobile/views/community_forum_page.dart';
import 'package:mobile/views/medication_reminder.dart';
import 'package:mobile/views/medicine/medicine_screen.dart';
import 'package:mobile/views/pages/general_search_page.dart';
import 'package:mobile/views/patient/patient_list_page.dart';
import 'package:mobile/views/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  final List<String> _announcements = [
    "Yeni ilaç etkileşim veritabanı yüklendi! Artık daha kapsamlı kontroller yapabilirsiniz.",
    "Yeni güncelleme: Topluluk forumu eklendi! Meslektaşlarınla bilgi paylaşabilirsin.",
    "E-reçete entegrasyonu güncellendi. Daha hızlı reçete erişimi için uygulamayı keşfedin."
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/background-2.jpg'), context);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Geliştirilmiş Üst Bölüm
            _buildHeader(context, colorScheme),

            // Duyuru alanı
            _buildAnnouncementBanner(context, colorScheme),

            // Ana Menü Seçimleri (Sekmeler)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                indicatorWeight: 5,
                labelColor: colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                dividerHeight: 0,
                tabs: const [
                  Tab(text: "Ana Modüller"),
                  Tab(text: "Ek Özellikler"),
                ],
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),

            // Sekmelerin İçeriği
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Ana Modüller Sekmesi
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildShortcutCard(
                        context,
                        ActiveIngredientScreen(
                            backgroundColor: colorScheme.primary),
                        "assets/medicine.png",
                        "Etkin Madde Tespit",
                        description: "İlaçların etken maddelerini incele",
                        isNew: true,
                        borderColor: colorScheme.primary,
                      ),
                      _buildShortcutCard(
                        context,
                        MedicineScreen(backgroundColor: colorScheme.error),
                        "assets/medicine-2.png",
                        "İlaç Tespit",
                        description: "İlaç bilgilerini sorgula",
                        borderColor: colorScheme.error,
                      ),
                      _buildShortcutCard(
                        context,
                        PatientListPage(backgroundColor: Colors.green),
                        "assets/patient.png",
                        "Hasta Yönetimi",
                        description: "Hasta bilgilerini yönet",
                        borderColor: Colors.green,
                      ),
                      _buildShortcutCard(
                        context,
                        SettingsScreen(backgroundColor: Colors.orange),
                        "assets/settings.png",
                        "Ayarlar",
                        description: "Uygulama ayarlarını düzenle",
                        borderColor: Colors.orange,
                      ),
                    ],
                  ),

                  // Ek Özellikler Sekmesi
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildShortcutCard(
                        context,
                        MedicationReminderPage(),
                        "assets/reminder.png",
                        "İlaç Hatırlatıcı",
                        description: "Hasta ilaç hatırlatıcısı oluştur",
                        isNew: true,
                        borderColor: Colors.blue,
                      ),
                      _buildShortcutCard(
                        context,
                        CommunityForumPage(),
                        "assets/communication.png",
                        "Topluluk Forumu",
                        description: "Meslektaşlarınla iletişim kur",
                        isNew: true,
                        borderColor: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Alt Bilgi
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "© 2024 Mustafa Toprak",
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "v1.2.0",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Geliştirilmiş Üst Bölüm
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: MediaQuery.sizeOf(context).height * .24,
      width: double.infinity,
      child: Stack(
        children: [
          // Arka plan görüntüsü ve degradesi
          Container(
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
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Başlık ve Alt başlık
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "TEBEMT",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "FARMASÖTİK BAKIM ASİSTANI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    "ETKİN MADDE TESPİTİ",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arama butonu
          Positioned(
            bottom: 15,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.search, color: colorScheme.primary),
                onPressed: () {
                  // Genel arama sayfasına yönlendirme
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GeneralSearchPage(),
                    ),
                  );
                },
                tooltip: 'Genel Arama',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Duyuru Banner'ı
  Widget _buildAnnouncementBanner(
      BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_outlined,
            color: colorScheme.primary,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Duyuru",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _announcements[_currentIndex % _announcements.length],
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 14),
            color: colorScheme.primary,
            onPressed: () {
              setState(() {
                _currentIndex++;
              });
            },
          ),
        ],
      ),
    );
  }

  // Geliştirilmiş Kısayol Kartı
  Widget _buildShortcutCard(
    BuildContext context,
    Widget page,
    String iconPath,
    String label, {
    required String description,
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
          border: Border.all(color: borderColor.withOpacity(0.2)),
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
