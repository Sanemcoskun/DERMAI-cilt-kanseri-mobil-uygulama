<?php
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Kredi paketleri tanımla
function getCreditPackages() {
    return [
        [
            'id' => 1,
            'name' => 'Başlangıç Paketi',
            'credits' => 10,
            'price' => 9.99,
            'currency' => 'TL',
            'description' => '10 kredi ile temel analizler',
            'popular' => false,
            'savings' => 0
        ],
        [
            'id' => 2,
            'name' => 'Standart Paket',
            'credits' => 25,
            'price' => 19.99,
            'currency' => 'TL',
            'description' => '25 kredi ile detaylı analizler',
            'popular' => true,
            'savings' => 15
        ],
        [
            'id' => 3,
            'name' => 'Premium Paket',
            'credits' => 50,
            'price' => 34.99,
            'currency' => 'TL',
            'description' => '50 kredi ile profesyonel analizler',
            'popular' => false,
            'savings' => 30
        ],
        [
            'id' => 4,
            'name' => 'Süper Paket',
            'credits' => 100,
            'price' => 59.99,
            'currency' => 'TL',
            'description' => '100 kredi ile sınırsız analizler',
            'popular' => false,
            'savings' => 40
        ]
    ];
}

try {
    $packages = getCreditPackages();
    
    ob_clean();
    echo json_encode([
        'success' => true,
        'data' => [
            'packages' => $packages,
            'total_packages' => count($packages),
            'currency' => 'TL',
            'last_updated' => date('Y-m-d H:i:s')
        ]
    ]);
    
} catch (Exception $e) {
    ob_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Paket bilgileri alınamadı: ' . $e->getMessage()
    ]);
}
?> 