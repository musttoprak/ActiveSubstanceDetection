import 'package:flutter/material.dart';

import '../../models/response_models/medicine_response_model.dart';
import 'medicine_detail_page.dart';

// İlaç ListTile widget'ı (ilaç listesinde her bir öğe için)
class MedicineListItem extends StatelessWidget {
  final MedicineResponseModel medicine;

  const MedicineListItem({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(.9),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          // İlaç detay sayfasına yönlendir
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineDetailPage(medicine: medicine),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication, color: Colors.blue),
          ),
          title: Text(
            medicine.ilacAdi != null && medicine.ilacAdi != '' ? medicine.ilacAdi! : 'İlaç Bilgisi',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (medicine.ureticiFirma != null && medicine.ureticiFirma!.isNotEmpty)
                Text("Üretici: ${medicine.ureticiFirma}"),
              if (medicine.miktar != null)
                Text("Miktar: ${medicine.miktar}"),
              if (medicine.receteTipi != null)
                Text("Reçete: ${medicine.receteTipi}"),
              if (medicine.sgkDurumu != null && medicine.sgkDurumu != "")
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: medicine.sgkDurumu!.toLowerCase().contains('ödenmez') ||
                        medicine.sgkDurumu!.toLowerCase().contains('ödemez')
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    medicine.sgkDurumu!,
                    style: TextStyle(
                      color: medicine.sgkDurumu!.toLowerCase().contains('ödenmez') ||
                          medicine.sgkDurumu!.toLowerCase().contains('ödemez')
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
            ],
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}

// İlaç listesi widget'ı
Widget buildMedicineList(List<MedicineResponseModel> medicines) {
  if (medicines.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "Bu etken madde için kayıtlı ilaç bulunmamaktadır.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  return ListView.builder(
    itemCount: medicines.length,
    itemBuilder: (context, index) {
      final medicine = medicines[index];
      return MedicineListItem(medicine: medicine);
    },
  );
}