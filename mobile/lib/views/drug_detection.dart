// Gelişmiş Arama Ekranı
import 'package:flutter/material.dart';

class DrugDetectionScreen extends StatelessWidget {
  final Color backgroundColor;

  const DrugDetectionScreen({super.key, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text("Gelişmiş İlaç Arama"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldTitle("Şekil"),
            _ImageField(),
            const SizedBox(height: 16),
            const _FieldTitle("Renk"),
            _ImageField(),
            const SizedBox(height: 16),
            _ToggleGroup(
              title: "Çentik",
              options: ["Çentikli", "Çentiksiz", "Tümü"],
              backgroundColor: backgroundColor,
            ),
            _ToggleGroup(
              title: "Logo",
              options: ["Var", "Yok", "Tümü"],
              backgroundColor: backgroundColor,
            ),
            _ToggleGroup(
              title: "Şeffaf",
              options: ["Evet", "Hayır", "Tümü"],
              backgroundColor: backgroundColor,
            ),
            _InputField(
              label: "Metin",
              hintText: "Metin eklemek için tıklayınız",
              backgroundColor: backgroundColor,
            ),
            _InputField(
              label: "ATC",
              hintText: "ATC Kodu eklemek için tıklayınız",
              backgroundColor: backgroundColor,
            ),
            _InputField(
              label: "Endikasyon",
              hintText: "Endikasyon seçmek için tıklayınız",
              backgroundColor: backgroundColor,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text("Filtreleri Temizle"),
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 16), // Butonlar arasında boşluk bırak
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: backgroundColor),
                    onPressed: () {},
                    child: const Text("Ara"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldTitle extends StatelessWidget {
  final String title;

  const _FieldTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _ImageField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text("Görsel Alanı"),
      ),
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final Color backgroundColor;

  const _ToggleGroup(
      {required this.title,
        required this.options,
        required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldTitle(title),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: options
              .map(
                (option) => OutlinedButton(
              child: Text(
                option,
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {},
            ),
          )
              .toList(),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hintText;
  final Color backgroundColor;

  const _InputField(
      {required this.label,
        required this.hintText,
        required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldTitle(label),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.black),
            fillColor: Colors.white,
            focusColor: Colors.white,
            hoverColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: backgroundColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: backgroundColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: backgroundColor),
            ),
          ),
        ),
      ],
    );
  }
}