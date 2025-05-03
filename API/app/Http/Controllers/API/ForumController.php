<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\ForumPost;
use App\Models\ForumComment;
use App\Models\Like;
use App\Models\User;
use App\Models\UserDetail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class ForumController extends Controller
{
    /**
     * Gönderileri listele.
     *
     * @param \Illuminate\Http\Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getPosts(Request $request)
    {
        try {
            $query = ForumPost::with(['user.detail', 'comments.user.detail'])
                ->withCount('likes')
                ->withCount('comments');

            // Kategori filtresi
            if ($request->has('category') && $request->category !== 'Tümü') {
                $query->where('category', $request->category);
            }

            // Arama filtresi
            if ($request->has('query') && !empty($request->query)) {
                $searchTerm = $request->query;
                $query->where(function ($q) use ($searchTerm) {
                    $q->where('title', 'like', "%{$searchTerm}%")
                        ->orWhere('content', 'like', "%{$searchTerm}%");
                });
            }

            // Sıralama
            $sortBy = $request->input('sort_by', 'created_at');
            $sortOrder = $request->input('sort_order', 'desc');

            if ($sortBy === 'popularity') {
                $query->orderByRaw('(likes_count + comments_count) DESC');
            } else {
                $query->orderBy($sortBy, $sortOrder);
            }

            $posts = $query->paginate(10);

            // Kullanıcı beğenilerini kontrol et
            $userLikes = [];
            if ($request->user_id) {
                $userId = $request->user_id;
                $likedPosts = Like::where('user_id', $userId)
                    ->where('likeable_type', ForumPost::class)
                    ->pluck('likeable_id')
                    ->toArray();

                $userLikes = [
                    'posts' => $likedPosts,
                ];
            }

            return response()->json([
                'status' => 'success',
                'data' => $posts,
                'user_likes' => $userLikes,
                'message' => 'Gönderiler başarıyla getirildi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gönderiler getirilirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Gönderi detayını getir.
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function getPost(Request $request, $id)
    {
        try {
            // Forum gönderisini kullanıcı detaylarıyla birlikte al
            $post = ForumPost::with(['user.detail', 'comments.user.detail'])
                ->withCount('likes')
                ->findOrFail($id);

            // Yorumları beğeni sayısına göre sırala
            $post->comments = $post->comments->sortByDesc(function ($comment) {
                return $comment->is_accepted ? PHP_INT_MAX : $comment->likes()->count();
            })->values();

            // Kullanıcı beğenilerini kontrol et
            $userLikes = [];
            if ($request->user_id) {
                $userId = $request->user_id;

                // Kullanıcı tarafından beğenilen yorumları al
                $likedComments = Like::where('user_id', $userId)
                    ->where('likeable_type', ForumComment::class)
                    ->whereIn('likeable_id', $post->comments->pluck('id')->toArray())
                    ->pluck('likeable_id')
                    ->toArray();

                // Kullanıcı tarafından beğenilen gönderi olup olmadığını kontrol et
                $postLiked = Like::where('user_id', $userId)
                    ->where('likeable_type', ForumPost::class)
                    ->where('likeable_id', $id)
                    ->exists();

                // User beğenileri düzenlenmiş formatta döndür
                $userLikes = [
                    'post' => $postLiked,  // Gönderinin beğenilip beğenilmediği
                    'comments' => $likedComments,  // Beğenilen yorumların ID'leri
                ];
            }

            // Gönderi ve kullanıcı beğenileriyle birlikte yanıt döndür
            return response()->json([
                'status' => 'success',
                'data' => $post,  // Gönderi verisi
                'user_likes' => $userLikes,  // Kullanıcı beğenileri
                'message' => 'Gönderi başarıyla getirildi'
            ]);
        } catch (\Exception $e) {
            // Hata durumunda mesaj döndür
            return response()->json([
                'status' => 'error',
                'message' => 'Gönderi getirilirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Yeni gönderi oluştur.
     *
     * @param \Illuminate\Http\Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function createPost(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'title' => 'required|string|max:255',
                'content2' => 'required|string',
                'category' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()
                ], 422);
            }

            $post = ForumPost::create([
                'user_id' => $request->user_id,
                'title' => $request->title,
                'content' => $request->content2,
                'category' => $request->category,
                'likes' => 0,
                'is_resolved' => false,
            ]);

            // Gönderi detayı ile birlikte dön
            $post->load('user.detail');

            return response()->json([
                'status' => 'success',
                'data' => $post,
                'message' => 'Gönderi başarıyla oluşturuldu'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gönderi oluşturulurken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Gönderiyi güncelle.
     *
     * @param \Illuminate\Http\Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function updatePost(Request $request, $id)
    {
        try {
            $post = ForumPost::findOrFail($id);

            // Yetki kontrolü
            if ($post->user_id !== $request->user_id) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu gönderiyi düzenleme yetkiniz yok'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'title' => 'sometimes|required|string|max:255',
                'content2' => 'sometimes|required|string',
                'category' => 'sometimes|required|string',
                'is_resolved' => 'sometimes|boolean',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()
                ], 422);
            }

            $post->update($request->only(['title', 'content', 'category', 'is_resolved']));

            // Gönderi detayı ile birlikte dön
            $post->load('user.detail');

            return response()->json([
                'status' => 'success',
                'data' => $post,
                'message' => 'Gönderi başarıyla güncellendi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gönderi güncellenirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Gönderiyi sil.
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function deletePost(Request $request, $id)
    {
        try {
            $post = ForumPost::findOrFail($id);

            // Yetki kontrolü
            if ($post->user_id !== $request->user_id) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu gönderiyi silme yetkiniz yok'
                ], 403);
            }

            $post->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Gönderi başarıyla silindi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gönderi silinirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Yorum ekle.
     *
     * @param \Illuminate\Http\Request $request
     * @param int $postId
     * @return \Illuminate\Http\JsonResponse
     */
    public function addComment(Request $request, $postId)
    {
        try {
            $post = ForumPost::findOrFail($postId);

            $validator = Validator::make($request->all(), [
                'content2' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()
                ], 422);
            }

            $comment = ForumComment::create([
                'post_id' => $postId,
                'user_id' => $request->user_id,
                'content' => $request->content2,
                'likes' => 0,
                'is_accepted' => false,
            ]);

            // Yorum detayı ile birlikte dön
            $comment->load('user.detail');

            return response()->json([
                'status' => 'success',
                'data' => $comment,
                'message' => 'Yorum başarıyla eklendi'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Yorum eklenirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Yorumu güncelle.
     *
     * @param \Illuminate\Http\Request $request
     * @param int $commentId
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateComment(Request $request, $commentId)
    {
        try {
            $comment = ForumComment::findOrFail($commentId);

            // Yetki kontrolü
            if ($comment->user_id !== $request->user_id) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu yorumu düzenleme yetkiniz yok'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'content2' => 'sometimes|required|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()
                ], 422);
            }

            $comment->update($request->only(['content']));

            // Yorum detayı ile birlikte dön
            $comment->load('user.detail');

            return response()->json([
                'status' => 'success',
                'data' => $comment,
                'message' => 'Yorum başarıyla güncellendi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Yorum güncellenirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Yorumu sil.
     *
     * @param int $commentId
     * @return \Illuminate\Http\JsonResponse
     */
    public function deleteComment(Request $request, $commentId)
    {
        try {
            $comment = ForumComment::findOrFail($commentId);

            // Yetki kontrolü
            if ($comment->user_id !== $request->user_id) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu yorumu silme yetkiniz yok'
                ], 403);
            }

            $comment->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Yorum başarıyla silindi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Yorum silinirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Yorumu kabul et.
     *
     * @param int $commentId
     * @return \Illuminate\Http\JsonResponse
     */
    public function acceptComment(Request $request, $commentId)
    {
        try {
            $comment = ForumComment::with('post')->findOrFail($commentId);
            $post = $comment->post;

            // Yetki kontrolü (sadece gönderi sahibi yorumu kabul edebilir)
            if ($post->user_id !== $request->user_id) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu yorumu kabul etme yetkiniz yok'
                ], 403);
            }

            // Tüm yorumları kabul edilmemiş olarak işaretle
            ForumComment::where('post_id', $post->id)
                ->update(['is_accepted' => false]);

            // İlgili yorumu kabul edilmiş olarak işaretle
            $comment->is_accepted = true;
            $comment->save();

            // Gönderiyi çözüldü olarak işaretle
            $post->is_resolved = true;
            $post->save();

            return response()->json([
                'status' => 'success',
                'data' => $comment,
                'message' => 'Yorum kabul edildi ve gönderi çözüldü olarak işaretlendi'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Yorum kabul edilirken bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Gönderi veya yorumu beğen.
     *
     * @param \Illuminate\Http\Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function like(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'likeable_id' => 'required|integer',
                'likeable_type' => 'required|in:post,comment',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()
                ], 422);
            }

            $userId = $request->user_id;
            $likeableId = $request->likeable_id;
            $likeableType = $request->likeable_type === 'post'
                ? ForumPost::class
                : ForumComment::class;

            // Daha önce beğenilmiş mi kontrol et
            $existingLike = Like::where('user_id', $userId)
                ->where('likeable_id', $likeableId)
                ->where('likeable_type', $likeableType)
                ->first();

            if ($existingLike) {
                // Beğeniyi kaldır
                $existingLike->delete();

                // Beğeni sayısını güncelle
                if ($likeableType === ForumPost::class) {
                    $item = ForumPost::find($likeableId);
                } else {
                    $item = ForumComment::find($likeableId);
                }

                if ($item) {
                    $item->decrement('likes');
                }

                return response()->json([
                    'status' => 'success',
                    'liked' => false,
                    'message' => 'Beğeni kaldırıldı'
                ]);
            } else {
                // Yeni beğeni ekle
                Like::create([
                    'user_id' => $userId,
                    'likeable_id' => $likeableId,
                    'likeable_type' => $likeableType,
                ]);

                // Beğeni sayısını güncelle
                if ($likeableType === ForumPost::class) {
                    $item = ForumPost::find($likeableId);
                } else {
                    $item = ForumComment::find($likeableId);
                }

                if ($item) {
                    $item->increment('likes');
                }

                return response()->json([
                    'status' => 'success',
                    'liked' => true,
                    'message' => 'Beğeni eklendi'
                ]);
            }
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Beğeni işlemi sırasında bir hata oluştu: ' . $e->getMessage()
            ], 500);
        }
    }
}
