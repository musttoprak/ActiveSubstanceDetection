<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Medicine;
use Exception;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PreparationsController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return LengthAwarePaginator
     */
    public function index(): LengthAwarePaginator
    {
        return Medicine::with('preparations')->paginate(10);
    }

    /**
     * Search preparations by name.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function search(Request $request): JsonResponse
    {
        try {
            $query = $request->input('name');
            if (!$query) {
                return response()->json([
                    'error' => false,
                    'message' => 'Returning all preparations.',
                    'data' => Medicine::with('preparations'),
                ], 200);
            }

            $preparations = Medicine::with('preparations')->where('name', 'like', '%' . $query . '%')->get();
            if ($preparations->isEmpty()) {
                return response()->json([
                    'error' => true,
                    'message' => 'No preparations found.',
                    'data' => [],
                ], 200);
            }

            return response()->json([
                'error' => false,
                'message' => 'Preparations found.',
                'data' => $preparations,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => true,
                'message' => 'Server error: ' . $e->getMessage(),
                'data' => [],
            ], 200);
        }
    }


    /**
     * Get preparation details by ID.
     *
     * @param int $id
     * @return JsonResponse
     */
    public function show(int $id)
    {
        if (!is_numeric($id)) {
            return response()->json([
                'error' => true,
                'message' => 'Invalid ID provided.',
                'data' => [],
            ], 200);
        }

        try {
            $preparation = Medicine::with('preparations')->findOrFail($id);
            return response()->json([
                'error' => false,
                'message' => 'Preparation found.',
                'data' => $preparation,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => true,
                'message' => 'Preparation not found.',
                'data' => [],
            ], 200);
        }
    }


    /**
     * Store a newly created resource in storage.
     *
     * @param Request $request
     * @return void
     */
    public function store(Request $request)
    {
        //
    }


    /**
     * Update the specified resource in storage.
     *
     * @param Request $request
     * @param int $id
     * @return void
     */
    public function update(Request $request, int $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param int $id
     * @return void
     */
    public function destroy(int $id)
    {
        //
    }
}
