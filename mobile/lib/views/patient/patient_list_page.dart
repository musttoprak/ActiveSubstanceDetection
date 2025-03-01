import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/patient_cubit.dart';
import 'package:mobile/models/response_models/patient_response_model.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({Key? key}) : super(key: key);

  @override
  _PatientListPageState createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientCubit>().getAllPatients();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      context.read<PatientCubit>().getAllPatients();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hastalar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Hasta Ara',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    context.read<PatientCubit>().searchPatients(_searchController.text);
                  },
                ),
                border: OutlineInputBorder(),
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
                  return const Center(child: Text('Hasta listesi yükleniyor...'));
                } else if (state is PatientLoading && context.read<PatientCubit>().allPatients.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PatientLoaded ||
                    (state is PatientLoading && context.read<PatientCubit>().allPatients.isNotEmpty)) {
                  List<PatientResponseModel> patients = [];

                  if (state is PatientLoaded) {
                    patients = state.patients;
                  } else if (state is PatientLoading) {
                    patients = context.read<PatientCubit>().allPatients;
                  }

                  return patients.isEmpty
                      ? const Center(child: Text('Hasta bulunamadı.'))
                      : RefreshIndicator(
                    onRefresh: () async {
                      await context.read<PatientCubit>().getAllPatients(refresh: true);
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: patients.length + (state is PatientLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == patients.length) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final patient = patients[index];
                        return ListTile(
                          title: Text('${patient.tamAd}'),
                          subtitle: Text('Yaş: ${patient.yas}, Cinsiyet: ${patient.cinsiyet}'),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/patient-detail',
                              arguments: patient.hastaId,
                            );
                          },
                        );
                      },
                    ),
                  );
                } else if (state is PatientError) {
                  return Center(child: Text('Hata: ${state.message}'));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}