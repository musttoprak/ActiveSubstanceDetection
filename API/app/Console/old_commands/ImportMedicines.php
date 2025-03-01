<?php

namespace App\Console\old_commands;

use App\Models\Medicine;
use App\Models\Preparation;
use Illuminate\Console\Command;

class ImportMedicines extends Command
{
    protected $signature = 'import:medicines {folder}';
    protected $description = 'Import medicines from JSON files in the given directory';

    public function handle(): void
    {
        $folder = $this->argument('folder');

        if (!is_dir($folder)) {
            $this->error("The specified folder does not exist.");
        }

        $files = glob($folder . '/*.json');

        foreach ($files as $file) {
            $this->importFile($file);
        }

        $this->info('All files imported successfully.');
    }

    private function importFile($file): void
    {
        $data = json_decode(file_get_contents($file), true);

        $medicine = Medicine::create([
            'name' => $data['İlaç Adı'],
            'image_src' => $data['Genel Bilgi']['image_src'] ?? null,
            'weight' => $data['Genel Bilgi']['table_data']['Net Kütle'] ?? null,
            'molecular_weight' => $data['Genel Bilgi']['table_data']['Molekül Ağırlığı'] ?? null,
            'formula' => $data['Genel Bilgi']['table_data']['Formül'] ?? null,
            'related_atc_codes' => $data['Genel Bilgi']['table_data']['İlişkili ATC Kodları'] ?? null,
            'cas' => $data['Genel Bilgi']['table_data']['CAS'] ?? null,
            'general_info' => $data['Genel Bilgi']['additional_info']['Genel Bilgi'] ?? null,
            'mechanism' => $data['Genel Bilgi']['additional_info']['Etki Mekanizması'] ?? null,
            'pharmacokinetics' => $data['Genel Bilgi']['additional_info']['Farmakokinetik'] ?? null,
        ]);

        foreach ($data['Müstahzarlar'] as $preparation) {
            Preparation::create([
                'medicine_id' => $medicine->id,
                'name' => $preparation[0],
                'company' => $preparation[1],
                'sgk_status' => $preparation[2],
                'link' => $preparation[3],
            ]);
        }
    }
}
