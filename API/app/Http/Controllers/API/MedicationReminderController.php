<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\MedicationReminder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class MedicationReminderController extends Controller
{
    /**
     * Hatırlatıcıları listele.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getReminders(Request $request)
    {
        try {
            $query = MedicationReminder::where('user_id', $request->user_id);

            // Tarih filtresi
            if ($request->has('date') && !empty($request->date)) {
                $date = Carbon::parse($request->date)->toDateString();
                $query->whereDate('reminder_date', $date);
            }

            // Hasta filtresi
            if ($request->has('patient_id') && !empty($request->patient_id)) {
                $query->where('patient_id', $request->patient_id);
            }

            // Tamamlanma durumu filtresi
            if ($request->has('is_complete') && $request->is_complete !== null) {
                $query->where('is_complete', $request->boolean('is_complete'));
            }

            $reminders = $query->orderBy('reminder_date', 'asc')
                ->orderBy('reminder_time', 'asc')
                ->get();

            return response()->json([
                'status' => 'success',
                'data' => $reminders,
                'message' => 'Hatırlatıcılar başarıyla getirildi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hatırlatıcılar getirilirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Belirli bir hatırlatıcıyı getir.
     *
     * @param  int  $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function getReminder($id)
    {
        try {
            $reminder = MedicationReminder::findOrFail($id);

            return response()->json([
                'status' => 'success',
                'data' => $reminder,
                'message' => 'Hatırlatıcı başarıyla getirildi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hatırlatıcı getirilirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Yeni bir hatırlatıcı oluştur.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function createReminder(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'user_id' => 'required|string',
                'patient_id' => 'required|string',
                'patient_name' => 'required|string',
                'medication_name' => 'required|string',
                'dose' => 'required|string',
                'reminder_time' => 'required|date_format:H:i',
                'reminder_date' => 'required|date',
                'notes' => 'nullable|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()
                ], 422);
            }

            $reminder = MedicationReminder::create([
                'user_id' => $request->user_id,
                'patient_id' => $request->patient_id,
                'patient_name' => $request->patient_name,
                'medication_name' => $request->medication_name,
                'dose' => $request->dose,
                'reminder_time' => $request->reminder_time,
                'reminder_date' => $request->reminder_date,
                'notes' => $request->notes,
                'is_complete' => false,
            ]);

            return response()->json([
                'status' => 'success',
                'data' => $reminder,
                'message' => 'Hatırlatıcı başarıyla oluşturuldu'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hatırlatıcı oluşturulurken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Bir hatırlatıcıyı güncelle.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateReminder(Request $request, $id)
    {
        try {
            $reminder = MedicationReminder::where('user_id', $request->user_id)
                ->findOrFail($id);

            $validator = Validator::make($request->all(), [
                'patient_id' => 'sometimes|required|string',
                'patient_name' => 'sometimes|required|string',
                'medication_name' => 'sometimes|required|string',
                'dose' => 'sometimes|required|string',
                'reminder_time' => 'sometimes|required|date_format:H:i',
                'reminder_date' => 'sometimes|required|date',
                'notes' => 'nullable|string',
                'is_complete' => 'sometimes|boolean',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()
                ], 422);
            }

            $reminder->update($request->all());

            return response()->json([
                'status' => 'success',
                'data' => $reminder,
                'message' => 'Hatırlatıcı başarıyla güncellendi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hatırlatıcı güncellenirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Bir hatırlatıcının tamamlanma durumunu değiştir.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function toggleComplete(Request $request, $id)
    {
        try {
            $reminder = MedicationReminder::where('user_id', $request->user_id)
                ->findOrFail($id);

            $reminder->is_complete = !$reminder->is_complete;
            $reminder->save();

            return response()->json([
                'status' => 'success',
                'data' => $reminder,
                'message' => 'Hatırlatıcı tamamlanma durumu güncellendi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hatırlatıcı tamamlanma durumu güncellenirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Belirli bir hatırlatıcıyı sil.
     *
     * @param  int  $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function deleteReminder($id)
    {
        try {
            $reminder = MedicationReminder::findOrFail($id);

            $reminder->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Hatırlatıcı başarıyla silindi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hatırlatıcı silinirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Belirli bir tarihteki hatırlatıcıları getir.
     *
     * @param  string  $date
     * @return \Illuminate\Http\JsonResponse
     */
    public function getRemindersByDate($date)
    {
        try {
            $formattedDate = Carbon::parse($date)->toDateString();

            $reminders = MedicationReminder::whereDate('reminder_date', $formattedDate)
                ->orderBy('reminder_time')
                ->get();

            return response()->json([
                'status' => 'success',
                'data' => $reminders,
                'message' => 'Hatırlatıcılar başarıyla getirildi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hatırlatıcılar getirilirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ay içindeki hatırlatıcı olan günleri getir.
     *
     * @param  int  $year
     * @param  int  $month
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMonthEvents(Request $request, $year, $month)
    {
        try {
            $startDate = Carbon::createFromDate($year, $month, 1)->startOfMonth();
            $endDate = Carbon::createFromDate($year, $month, 1)->endOfMonth();

            $days = MedicationReminder::where('user_id', $request->user_id)
                ->whereBetween('reminder_date', [$startDate, $endDate])
                ->select('reminder_date')
                ->distinct()
                ->pluck('reminder_date')
                ->map(function ($date) {
                    return Carbon::parse($date)->format('Y-m-d');
                });

            return response()->json([
                'status' => 'success',
                'data' => $days,
                'message' => 'Aylık hatırlatıcı günleri başarıyla getirildi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Aylık hatırlatıcı günleri getirilirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }
}
