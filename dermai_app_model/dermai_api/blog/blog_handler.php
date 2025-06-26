<?php
require_once __DIR__ . '/../config/database.php';

class BlogHandler {
    private static $db;
    
    private static function getDB() {
        if (!self::$db) {
            self::$db = Database::getInstance()->getConnection();
        }
        return self::$db;
    }
    
    public static function getBlogPosts() {
        try {
            $db = self::getDB();
            
            // Pagination parametreleri
            $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
            $limit = isset($_GET['limit']) ? max(1, min(20, intval($_GET['limit']))) : 5;
            $offset = ($page - 1) * $limit;
            
            // Toplam yazı sayısını al
            $countStmt = $db->prepare("SELECT COUNT(*) FROM blog_posts WHERE aktif = 1");
            $countStmt->execute();
            $totalPosts = $countStmt->fetchColumn();
            $totalPages = ceil($totalPosts / $limit);
            
            // Blog yazılarını getir (aktif olanlar)
            $stmt = $db->prepare("
                SELECT 
                    id,
                    baslik,
                    ozet,
                    icerik,
                    kapak_resmi,
                    kategori,
                    okunma_sayisi,
                    slayt_goster,
                    created_at,
                    updated_at
                FROM blog_posts 
                WHERE aktif = 1 
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
            ");
            $stmt->execute([$limit, $offset]);
            $posts = $stmt->fetchAll();
            
            // Tarihleri formatla ve görselleri ekle
            foreach ($posts as &$post) {
                $post['formatted_date'] = date('d.m.Y', strtotime($post['created_at']));
                $post['time_ago'] = self::timeAgo($post['created_at']);
                
                // Picsum'dan görsel ekle
                if (empty($post['kapak_resmi'])) {
                    $post['kapak_resmi'] = "https://picsum.photos/400/250?random=" . $post['id'];
                }
            }
            
            echo json_encode([
                'status' => 200,
                'message' => 'Blog yazıları başarıyla getirildi',
                'data' => $posts,
                'pagination' => [
                    'current_page' => $page,
                    'total_pages' => $totalPages,
                    'total_posts' => $totalPosts,
                    'per_page' => $limit,
                    'has_next' => $page < $totalPages,
                    'has_prev' => $page > 1
                ]
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Blog yazıları getirilirken hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    public static function getBlogPost($id) {
        try {
            $db = self::getDB();
            
            // Belirli blog yazısını getir
            $stmt = $db->prepare("
                SELECT 
                    id,
                    baslik,
                    ozet,
                    icerik,
                    kapak_resmi,
                    yazar,
                    kategori,
                    okunma_sayisi,
                    created_at,
                    updated_at
                FROM blog_posts 
                WHERE id = ? AND aktif = 1
            ");
            $stmt->execute([$id]);
            $post = $stmt->fetch();
            
            if (!$post) {
                http_response_code(404);
                echo json_encode([
                    'status' => 404,
                    'message' => 'Blog yazısı bulunamadı'
                ]);
                return;
            }
            
            // Okunma sayısını artır
            $stmt = $db->prepare("UPDATE blog_posts SET okunma_sayisi = okunma_sayisi + 1 WHERE id = ?");
            $stmt->execute([$id]);
            $post['okunma_sayisi']++;
            
            // Tarihleri formatla
            $post['formatted_date'] = date('d.m.Y', strtotime($post['created_at']));
            $post['time_ago'] = self::timeAgo($post['created_at']);
            
            echo json_encode([
                'status' => 200,
                'message' => 'Blog yazısı başarıyla getirildi',
                'data' => $post
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Blog yazısı getirilirken hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    public static function getBlogCategories() {
        try {
            $db = self::getDB();
            
            // Kategorileri getir
            $stmt = $db->prepare("
                SELECT DISTINCT kategori as name, COUNT(*) as count 
                FROM blog_posts 
                WHERE aktif = 1 
                GROUP BY kategori 
                ORDER BY count DESC
            ");
            $stmt->execute();
            $categories = $stmt->fetchAll();
            
            echo json_encode([
                'status' => 200,
                'message' => 'Blog kategorileri başarıyla getirildi',
                'data' => $categories
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Blog kategorileri getirilirken hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    public static function getSliderPosts() {
        try {
            $db = self::getDB();
            
            // Slayt için aktif yazıları getir
            $stmt = $db->prepare("
                SELECT 
                    id,
                    baslik,
                    ozet,
                    kapak_resmi,
                    kategori,
                    okunma_sayisi,
                    created_at
                FROM blog_posts 
                WHERE aktif = 1 AND slayt_goster = 1
                ORDER BY created_at DESC
                LIMIT 5
            ");
            $stmt->execute();
            $posts = $stmt->fetchAll();
            
            // Tarihleri formatla ve görselleri ekle
            foreach ($posts as &$post) {
                $post['formatted_date'] = date('d.m.Y', strtotime($post['created_at']));
                $post['time_ago'] = self::timeAgo($post['created_at']);
                
                // Picsum'dan görsel ekle
                if (empty($post['kapak_resmi'])) {
                    $post['kapak_resmi'] = "https://picsum.photos/600/300?random=" . $post['id'];
                }
            }
            
            echo json_encode([
                'status' => 200,
                'message' => 'Slayt yazıları başarıyla getirildi',
                'data' => $posts
            ]);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'status' => 500,
                'message' => 'Slayt yazıları getirilirken hata oluştu: ' . $e->getMessage()
            ]);
        }
    }
    
    private static function timeAgo($datetime) {
        $time = time() - strtotime($datetime);
        
        if ($time < 60) return 'Az önce';
        if ($time < 3600) return floor($time/60) . ' dakika önce';
        if ($time < 86400) return floor($time/3600) . ' saat önce';
        if ($time < 2592000) return floor($time/86400) . ' gün önce';
        if ($time < 31104000) return floor($time/2592000) . ' ay önce';
        return floor($time/31104000) . ' yıl önce';
    }
}

// API endpoint yönlendirmesi
$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['PATH_INFO'] ?? '';

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Session-ID');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

switch($path) {
    case '/posts':
        if ($method === 'GET') {
            BlogHandler::getBlogPosts();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/slider':
        if ($method === 'GET') {
            BlogHandler::getSliderPosts();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    case '/categories':
        if ($method === 'GET') {
            BlogHandler::getBlogCategories();
        } else {
            http_response_code(405);
            echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
        }
        break;
        
    default:
        // /post/{id} formatını kontrol et
        if (preg_match('/^\/post\/(\d+)$/', $path, $matches)) {
            if ($method === 'GET') {
                BlogHandler::getBlogPost($matches[1]);
            } else {
                http_response_code(405);
                echo json_encode(['status' => 405, 'message' => 'Method not allowed']);
            }
        } else {
            http_response_code(404);
            echo json_encode([
                'status' => 404,
                'message' => 'Endpoint bulunamadı',
                'available_endpoints' => [
                    'GET /posts - Tüm blog yazıları',
                    'GET /post/{id} - Belirli blog yazısı',
                    'GET /categories - Blog kategorileri'
                ]
            ]);
        }
        break;
}
?> 