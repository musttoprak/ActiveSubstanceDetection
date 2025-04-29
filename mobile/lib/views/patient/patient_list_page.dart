// pages/patient_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/patient_cubit.dart';
import 'package:mobile/models/response_models/patient_response_model.dart';
import 'package:mobile/views/patient/patient_detail_page.dart';

class PatientListPage extends StatefulWidget {
  final Color backgroundColor;

  const PatientListPage({super.key, required this.backgroundColor});

  @override
  _PatientListPageState createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientCubit()..getAllPatients(),
      child: BlocBuilder<PatientCubit, PatientState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: widget.backgroundColor,
              title: const Text('Hastalar'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Hasta Ara',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            context
                                .read<PatientCubit>()
                                .searchPatients(_searchController.text);
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        context.read<PatientCubit>().searchPatients(value);
                      },
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<PatientCubit, PatientState>(
                      builder: (context, state) {
                        if (state is PatientInitial) {
                          return const Center(
                              child: Text('Hasta listesi yükleniyor...'));
                        } else if (state is PatientLoading &&
                            context.read<PatientCubit>().allPatients.isEmpty) {
                          return Center(child: CircularProgressIndicator(color: widget.backgroundColor));
                        } else if (state is PatientLoaded ||
                            (state is PatientLoading &&
                                context
                                    .read<PatientCubit>()
                                    .allPatients
                                    .isNotEmpty)) {
                          List<PatientResponseModel> patients = [];

                          if (state is PatientLoaded) {
                            patients = state.patients;
                          } else if (state is PatientLoading) {
                            patients = context.read<PatientCubit>().allPatients;
                          }

                          return patients.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hasta bulunamadı.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : StatefulBuilder(builder: (BuildContext context,
                              void Function(void Function()) setState) {
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                              if (_scrollController.hasClients &&
                                  !_scrollController.hasListeners) {
                                _scrollController.addListener(() {
                                  if (_scrollController.position.pixels ==
                                      _scrollController
                                          .position.maxScrollExtent) {
                                    context
                                        .read<PatientCubit>()
                                        .getAllPatients();
                                  }
                                });
                              }
                            });

                            return RefreshIndicator(
                              onRefresh: () async {
                                await context
                                    .read<PatientCubit>()
                                    .getAllPatients(refresh: true);
                              },
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                itemCount: patients.length +
                                    (state is PatientLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == patients.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                          child:
                                          CircularProgressIndicator()),
                                    );
                                  }

                                  final patient = patients[index];

                                  // Cinsiyet için ikon belirleme
                                  IconData genderIcon;
                                  Color genderColor;

                                  if (patient.cinsiyet.toLowerCase() == 'erkek') {
                                    genderIcon = Icons.male;
                                    genderColor = Colors.blue;
                                  } else if (patient.cinsiyet.toLowerCase() == 'kadın') {
                                    genderIcon = Icons.female;
                                    genderColor = Colors.pink;
                                  } else {
                                    genderIcon = Icons.person;
                                    genderColor = Colors.purple;
                                  }

                                  // İsmin baş harflerini alma
                                  String initials = patient.tamAd
                                      .split(' ')
                                      .map((word) => word.isNotEmpty ? word[0] : '')
                                      .join('')
                                      .toUpperCase();
                                  if (initials.length > 2) {
                                    initials = initials.substring(0, 2);
                                  }

                                  // Her hastanın ID'sine göre farklı renk tonu hesaplama
                                  final int colorSeed = patient.hastaId.hashCode;
                                  final Color cardColor = Color.fromRGBO(
                                    245, // Açık bir kırmızı-pembe tonu
                                    250, // Yüksek yeşil değeri ile soft pastel
                                    255, // Maksimum mavi ile ferahlık hissi
                                    1.0,
                                  );

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PatientDetailPage(
                                                  hastaId: patient.hastaId,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor: widget.backgroundColor.withOpacity(.6),
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Hasta bilgileri
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    patient.tamAd,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Yaş: ${patient.yas}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Icon(
                                                        genderIcon,
                                                        size: 18,
                                                        color: genderColor,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        patient.cinsiyet,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Sağ ok
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 18,
                                              color: Colors.grey[400],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          });
                        } else if (state is PatientError) {
                          return Center(child: Text('Hata: ${state.message}'));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
