// lib/views/reminder/medication_reminder.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/reminder_cubit.dart';
import 'package:mobile/models/response_models/medication_reminder_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'reminder_form.dart';

class MedicationReminderPage extends StatefulWidget {
  const MedicationReminderPage({Key? key}) : super(key: key);

  @override
  _MedicationReminderPageState createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  List<String> _eventDays = [];

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.week;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    // Başlangıçta bugünkü hatırlatıcıları yükle
    _loadRemindersForDate(_selectedDay!);
    // Aylık hatırlatıcı günlerini yükle
    _loadMonthEvents(_focusedDay.year, _focusedDay.month);
  }

  Future<void> _loadRemindersForDate(DateTime date) async {
    // ReminderCubit üzerinden belirli bir tarih için hatırlatıcıları yükle
    BlocProvider.of<ReminderCubit>(context).getRemindersForDate(date);
  }

  Future<void> _loadMonthEvents(int year, int month) async {
    // ReminderCubit üzerinden aylık etkinlik günlerini yükle
    final days = await BlocProvider.of<ReminderCubit>(context).getMonthEvents(year, month);

    setState(() {
      _eventDays = days;
    });
  }

  // Belirli günde hatırlatıcı var mı kontrol et (Calendar için)
  bool _hasRemindersOnDay(DateTime day) {
    final formattedDay = DateFormat('yyyy-MM-dd').format(day);
    return _eventDays.contains(formattedDay);
  }

  // Hatırlatıcının tamamlandı durumunu değiştir
  Future<void> _toggleReminderComplete(int reminderId) async {
    // ReminderCubit üzerinden hatırlatıcı durumunu değiştir
    await BlocProvider.of<ReminderCubit>(context).toggleComplete(reminderId);
  }

  // Hatırlatıcıyı sil
  Future<void> _deleteReminder(int reminderId) async {
    final confirmed = await _showDeleteConfirmDialog();
    if (confirmed) {
      // ReminderCubit üzerinden hatırlatıcıyı sil
      await BlocProvider.of<ReminderCubit>(context).deleteReminder(reminderId);

      // Aylık etkinlikleri yeniden yükle
      _loadMonthEvents(_focusedDay.year, _focusedDay.month);
    }
  }

  // Silme onayı diyaloğu
  Future<bool> _showDeleteConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hatırlatıcı Silme'),
        content: Text('Bu hatırlatıcıyı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Yeni hatırlatıcı ekleme diyaloğu
  void _showAddReminderDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderFormPage(
          selectedDate: _selectedDay ?? DateTime.now(),
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Yeni hatırlatıcı eklendiğinde tarihe göre hatırlatıcıları yeniden yükle
        if (_selectedDay != null) {
          _loadRemindersForDate(_selectedDay!);
        }
        // Aylık etkinlikleri yeniden yükle
        _loadMonthEvents(_focusedDay.year, _focusedDay.month);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('İlaç Hatırlatıcı'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Takvim
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadRemindersForDate(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadMonthEvents(focusedDay.year, focusedDay.month);
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            eventLoader: (day) {
              // Belirli günde hatırlatıcı var mı göster
              return _hasRemindersOnDay(day) ? [Object()] : [];
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.blue,
              ),
            ),
          ),

          // Seçili günün hatırlatıcıları
          Expanded(
            child: BlocConsumer<ReminderCubit, ReminderState>(
              listener: (context, state) {
                if (state is ReminderError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ReminderLoading) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is ReminderLoaded) {
                  return _buildReminderList(state.reminders);
                } else {
                  return Center(
                    child: Text('Hatırlatıcılar yüklenirken bir hata oluştu'),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
        tooltip: 'Hatırlatıcı Ekle',
      ),
    );
  }

  Widget _buildReminderList(List<MedicationReminder> reminders) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Bu gün için hatırlatıcı yok',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Yeni hatırlatıcı eklemek için + butonuna tıklayın',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Saate göre sırala
    reminders.sort((a, b) {
      final aTime = a.getTimeOfDay();
      final bTime = b.getTimeOfDay();
      final aMinutes = aTime.hour * 60 + aTime.minute;
      final bMinutes = bTime.hour * 60 + bTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        return _buildReminderCard(reminders[index]);
      },
    );
  }

  Widget _buildReminderCard(MedicationReminder reminder) {
    final isPast = _isPastReminder(reminder);

    return Dismissible(
      key: Key('reminder_${reminder.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmDialog(),
      onDismissed: (direction) => _deleteReminder(reminder.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: reminder.isComplete
                ? Colors.green.withOpacity(0.5)
                : isPast
                ? Colors.red.withOpacity(0.5)
                : Colors.blue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            // Hatırlatıcı detayını göster veya düzenle
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İlaç ikonu
                Container(
                  decoration: BoxDecoration(
                    color: reminder.isComplete
                        ? Colors.green.withOpacity(0.1)
                        : isPast
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.medication_outlined,
                    color: reminder.isComplete
                        ? Colors.green
                        : isPast
                        ? Colors.red
                        : Colors.blue,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),

                // İlaç bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicationName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              reminder.dose,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Text(
                            reminder.reminderTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Text(
                            reminder.patientName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (reminder.notes != null && reminder.notes!.isNotEmpty)
                        SizedBox(height: 4),
                      if (reminder.notes != null && reminder.notes!.isNotEmpty)
                        Text(
                          reminder.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),

                // Tamamlandı/Tamamlanmadı düğmesi
                Checkbox(
                  value: reminder.isComplete,
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (value) {
                    _toggleReminderComplete(reminder.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isPastReminder(MedicationReminder reminder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = reminder.reminderDate;

    if (today.isAfter(reminderDate)) {
      return true;
    } else if (today.isAtSameMomentAs(reminderDate)) {
      final timeOfDay = reminder.getTimeOfDay();
      final currentMinutes = now.hour * 60 + now.minute;
      final reminderMinutes = timeOfDay.hour * 60 + timeOfDay.minute;
      return currentMinutes > reminderMinutes;
    }

    return false;
  }
}