<?php

namespace App\Imports;

use Maatwebsite\Excel\Concerns\ToArray;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithChunkReading;

class IlacImport implements ToArray, WithHeadingRow, WithChunkReading
{
    protected $data;

    public function __construct(&$data)
    {
        $this->data = &$data;
    }

    public function array(array $rows)
    {
        // Boş olmayan satırları al
        foreach ($rows as $row) {
            // Boş satırları atla
            if (empty(array_filter($row))) {
                continue;
            }

            $this->data[] = $row;
        }
    }

    public function headingRow(): int
    {
        return 1; // Excel'deki başlık satırı (genellikle 1. satır)
    }

    public function chunkSize(): int
    {
        return 500; // Bellek kullanımını düşürmek için 500'er satır oku
    }
}

class AktifUrunlerSheet implements ToArray, WithHeadingRow, WithChunkReading
{
    protected $data;

    public function __construct(&$data)
    {
        $this->data = &$data;
    }

    public function array(array $rows)
    {
        // Başlık satırını temizle ve boş olmayan satırları al
        foreach ($rows as $row) {
            // Boş satırları atla
            if (empty(array_filter($row))) {
                continue;
            }

            $this->data[] = $row;
        }
    }

    public function headingRow(): int
    {
        return 1; // Excel'deki başlık satırı (genellikle 1. satır)
    }

    public function chunkSize(): int
    {
        return 500; // Bellek kullanımını düşürmek için 500'er satır oku
    }
}
