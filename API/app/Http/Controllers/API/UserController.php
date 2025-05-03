<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserDetail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class UserController extends Controller
{
    /**
     * Kullanıcının profilini getir.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getProfile()
    {
        try {
            $user = User::with('detail')->findOrFail(Auth::id());

            return response()->json([
                'status' => 'success',
                'data' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'name' => $user->detail ? $user->detail->name : null,
                    'role' => $user->detail ? $user->detail->role : null,
                    'profile_picture' => $user->detail ? $user->detail->profile_picture : null,
                ],
                'message' => 'Profil başarıyla getirildi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Profil getirilirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Kullanıcının profilini güncelle.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateProfile(Request $request)
    {
        try {
            $user = User::findOrFail(Auth::id());

            $validator = Validator::make($request->all(), [
                'name' => 'sometimes|required|string|max:255',
                'role' => 'sometimes|required|string|max:255',
                'profile_picture' => 'sometimes|nullable|image|max:2048', // 2MB max
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()
                ], 422);
            }

            // UserDetail oluştur veya güncelle
            $userDetail = UserDetail::firstOrNew(['user_id' => $user->id]);

            if ($request->has('name')) {
                $userDetail->name = $request->name;
            }

            if ($request->has('role')) {
                $userDetail->role = $request->role;
            }

            // Profil resmi yükleme
            if ($request->hasFile('profile_picture')) {
                // Eski resmi sil
                if ($userDetail->profile_picture) {
                    Storage::disk('public')->delete($userDetail->profile_picture);
                }

                $path = $request->file('profile_picture')->store('profile-pictures', 'public');
                $userDetail->profile_picture = $path;
            }

            $userDetail->save();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'id' => $user->id,
                    'email' => $user->email,
                    'name' => $userDetail->name,
                    'role' => $userDetail->role,
                    'profile_picture' => $userDetail->profile_picture,
                ],
                'message' => 'Profil başarıyla güncellendi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Profil güncellenirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }
}
