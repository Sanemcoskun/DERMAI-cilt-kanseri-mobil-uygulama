<?php

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../src/Database.php';
require_once __DIR__ . '/../src/Utils.php';
require_once __DIR__ . '/../src/GeminiClient.php';

$method = $_SERVER['REQUEST_METHOD'];
$input = Utils::getInput();
$db = Database::getInstance();

switch ($method) {
    case 'GET':
        $action = $_GET['action'] ?? 'conversations';
        
        switch ($action) {
            case 'conversations':
                handleGetConversations($db);
                break;
            case 'messages':
                $conversationId = $_GET['conversation_id'] ?? null;
                if (!$conversationId) Utils::sendError('Konuşma ID gerekli', 400);
                handleGetMessages($conversationId, $db);
                break;
            case 'history':
                handleGetHistory($db);
                break;
            default:
                Utils::sendError('Geçersiz aksiyon', 400);
        }
        break;
        
    case 'POST':
        $action = $_GET['action'] ?? '';
        
        switch ($action) {
            case 'send':
                handleSendMessage($input, $db);
                break;
            case 'new-conversation':
                handleNewConversation($input, $db);
                break;
            case 'analyze-skin':
                handleSkinAnalysis($db);
                break;
            default:
                Utils::sendError('Geçersiz aksiyon', 400);
        }
        break;
        
    case 'DELETE':
        $action = $_GET['action'] ?? '';
        
        switch ($action) {
            case 'conversation':
                $conversationId = $_GET['conversation_id'] ?? null;
                if (!$conversationId) Utils::sendError('Konuşma ID gerekli', 400);
                handleDeleteConversation($conversationId, $db);
                break;
            default:
                Utils::sendError('Geçersiz aksiyon', 400);
        }
        break;
        
    default:
        Utils::sendError('Desteklenmeyen HTTP metodu', 405);
}

function handleGetConversations($db) {
    $userId = Utils::getAuthUser();
    $page = (int)($_GET['page'] ?? 1);
    $limit = (int)($_GET['limit'] ?? 20);
    $offset = ($page - 1) * $limit;
    
    // Count query
    $countSql = "SELECT COUNT(*) as total FROM chat_conversations WHERE user_id = ?";
    $totalResult = $db->fetch($countSql, [$userId]);
    $total = $totalResult['total'];
    
    // Data query with last message
    $conversations = $db->fetchAll("
        SELECT 
            cc.id, cc.title, cc.created_at, cc.updated_at,
            (SELECT cm.message FROM chat_messages cm 
             WHERE cm.conversation_id = cc.id 
             ORDER BY cm.created_at DESC LIMIT 1) as last_message,
            (SELECT cm.created_at FROM chat_messages cm 
             WHERE cm.conversation_id = cc.id 
             ORDER BY cm.created_at DESC LIMIT 1) as last_message_time,
            (SELECT COUNT(*) FROM chat_messages cm 
             WHERE cm.conversation_id = cc.id) as message_count
        FROM chat_conversations cc
        WHERE cc.user_id = ?
        ORDER BY cc.updated_at DESC
        LIMIT ? OFFSET ?
    ", [$userId, $limit, $offset]);
    
    foreach ($conversations as &$conversation) {
        $conversation['message_count'] = (int)$conversation['message_count'];
        $conversation['last_message'] = $conversation['last_message'] ? 
            (strlen($conversation['last_message']) > 100 ? 
                substr($conversation['last_message'], 0, 100) . '...' : 
                $conversation['last_message']) : 
            'Henüz mesaj yok';
    }
    
    Utils::sendResponse([
        'conversations' => $conversations,
        'pagination' => [
            'current_page' => $page,
            'per_page' => $limit,
            'total' => (int)$total,
            'total_pages' => ceil($total / $limit)
        ]
    ]);
}

function handleGetMessages($conversationId, $db) {
    $userId = Utils::getAuthUser();
    
    // Check if conversation belongs to user
    $conversation = $db->fetch("
        SELECT id, title FROM chat_conversations 
        WHERE id = ? AND user_id = ?
    ", [$conversationId, $userId]);
    
    if (!$conversation) {
        Utils::sendError('Konuşma bulunamadı', 404);
    }
    
    $messages = $db->fetchAll("
        SELECT 
            id, message, message_type, image_path, diagnosis_result,
            credits_used, created_at,
            DATE_FORMAT(created_at, '%d.%m.%Y %H:%i') as formatted_time
        FROM chat_messages 
        WHERE conversation_id = ? 
        ORDER BY created_at ASC
    ", [$conversationId]);
    
    foreach ($messages as &$message) {
        $message['diagnosis_result'] = $message['diagnosis_result'] ? 
            json_decode($message['diagnosis_result'], true) : null;
        $message['credits_used'] = (int)$message['credits_used'];
    }
    
    Utils::sendResponse([
        'conversation' => $conversation,
        'messages' => $messages
    ]);
}

function handleSendMessage($input, $db) {
    $userId = Utils::getAuthUser();
    
    Utils::validateRequired($input, ['conversation_id', 'message']);
    
    $conversationId = $input['conversation_id'];
    $message = Utils::sanitizeString($input['message']);
    
    // Check if conversation belongs to user
    $conversation = $db->fetch("
        SELECT id FROM chat_conversations 
        WHERE id = ? AND user_id = ?
    ", [$conversationId, $userId]);
    
    if (!$conversation) {
        Utils::sendError('Konuşma bulunamadı', 404);
    }
    
    // Check user credits
    $user = $db->fetch("SELECT credits FROM users WHERE id = ?", [$userId]);
    if ($user['credits'] < 1) {
        Utils::sendError('Yetersiz kredi', 402);
    }
    
    try {
        $db->beginTransaction();
        
        // Save user message
        $userMessageId = $db->insert('chat_messages', [
            'conversation_id' => $conversationId,
            'user_id' => $userId,
            'message' => $message,
            'message_type' => 'user'
        ]);
        
        // Get conversation history
        $history = $db->fetchAll("
            SELECT message, message_type 
            FROM chat_messages 
            WHERE conversation_id = ? 
            ORDER BY created_at DESC 
            LIMIT ?
        ", [$conversationId, MAX_HISTORY_MESSAGES]);
        
        // Prepare context for AI
        $context = "Sen bir cilt kanseri teşhis asistanısın. Kullanıcılara cilt lezyonları hakkında bilgi veren, dikkatli ve sorumlu tavsiyelerde bulunan bir AI'sın. Her zaman doktor konsültasyonu önermelisin.";
        
        $geminiClient = new GeminiClient();
        $aiResponse = $geminiClient->generateResponse($message, $history, $context);
        
        // Save AI response
        $aiMessageId = $db->insert('chat_messages', [
            'conversation_id' => $conversationId,
            'user_id' => $userId,
            'message' => $aiResponse,
            'message_type' => 'ai',
            'credits_used' => 1
        ]);
        
        // Deduct credit
        $db->update('users', [
            'credits' => 'credits - 1'
        ], 'id = ?', [$userId]);
        
        // Add credit transaction
        $db->insert('credit_transactions', [
            'user_id' => $userId,
            'amount' => -1,
            'transaction_type' => 'spent',
            'description' => 'Chat mesajı',
            'related_activity_id' => $aiMessageId
        ]);
        
        // Update conversation timestamp
        $db->update('chat_conversations', [
            'updated_at' => date('Y-m-d H:i:s')
        ], 'id = ?', [$conversationId]);
        
        // Log activity
        Utils::logActivity($userId, 'chat', [
            'conversation_id' => $conversationId,
            'message_length' => strlen($message)
        ]);
        
        $db->commit();
        
        Utils::sendResponse([
            'user_message' => [
                'id' => $userMessageId,
                'message' => $message,
                'message_type' => 'user',
                'created_at' => date('Y-m-d H:i:s')
            ],
            'ai_response' => [
                'id' => $aiMessageId,
                'message' => $aiResponse,
                'message_type' => 'ai',
                'created_at' => date('Y-m-d H:i:s')
            ],
            'credits_used' => 1
        ]);
        
    } catch (Exception $e) {
        $db->rollback();
        Utils::sendError('Mesaj gönderilemedi: ' . $e->getMessage(), 500);
    }
}

function handleNewConversation($input, $db) {
    $userId = Utils::getAuthUser();
    
    $title = isset($input['title']) ? Utils::sanitizeString($input['title']) : 'Yeni Konuşma';
    
    $conversationId = $db->insert('chat_conversations', [
        'user_id' => $userId,
        'title' => $title
    ]);
    
    Utils::sendResponse([
        'conversation_id' => $conversationId,
        'title' => $title,
        'created_at' => date('Y-m-d H:i:s')
    ]);
}

function handleSkinAnalysis($db) {
    $userId = Utils::getAuthUser();
    
    if (!isset($_FILES['skin_image'])) {
        Utils::sendError('Cilt görüntüsü gerekli', 400);
    }
    
    // Check user credits
    $user = $db->fetch("SELECT credits FROM users WHERE id = ?", [$userId]);
    if ($user['credits'] < 2) { // Analiz 2 kredi tutar
        Utils::sendError('Yetersiz kredi (Analiz için 2 kredi gerekli)', 402);
    }
    
    try {
        $db->beginTransaction();
        
        // Upload image
        $imagePath = Utils::uploadImage($_FILES['skin_image'], 'skin');
        
        // Create or get conversation
        $conversationId = $_POST['conversation_id'] ?? null;
        if (!$conversationId) {
            $conversationId = $db->insert('chat_conversations', [
                'user_id' => $userId,
                'title' => 'Cilt Analizi - ' . date('d.m.Y H:i')
            ]);
        }
        
        // Mock analysis (gerçek uygulamada AI modeli kullanılacak)
        $analysisResult = [
            'risk_level' => 'medium',
            'confidence' => 0.75,
            'findings' => [
                'Düzensiz kenarlar gözlemlendi',
                'Renk varyasyonu mevcut',
                'Asimetri tespit edildi'
            ],
            'recommendations' => [
                'Dermatoloji uzmanına başvurun',
                'Düzenli takip yapın',
                'Güneşten korunun'
            ]
        ];
        
        $riskLevel = $analysisResult['risk_level'];
        $recommendations = implode('. ', $analysisResult['recommendations']);
        
        // Save analysis
        $analysisId = $db->insert('skin_analyses', [
            'user_id' => $userId,
            'conversation_id' => $conversationId,
            'image_path' => $imagePath,
            'original_image_name' => $_FILES['skin_image']['name'],
            'analysis_result' => json_encode($analysisResult),
            'confidence_score' => $analysisResult['confidence'],
            'risk_level' => $riskLevel,
            'recommendations' => $recommendations,
            'doctor_referral' => $riskLevel === 'high' || $riskLevel === 'critical' ? 1 : 0,
            'credits_used' => 2
        ]);
        
        // Save user message
        $userMessage = "Cilt analizi talebi: " . $_FILES['skin_image']['name'];
        $userMessageId = $db->insert('chat_messages', [
            'conversation_id' => $conversationId,
            'user_id' => $userId,
            'message' => $userMessage,
            'message_type' => 'user',
            'image_path' => $imagePath
        ]);
        
        // Generate AI response
        $aiMessage = "Cilt analizi tamamlandı.\n\n";
        $aiMessage .= "Risk Seviyesi: " . ucfirst($riskLevel) . "\n";
        $aiMessage .= "Güven Skoru: " . ($analysisResult['confidence'] * 100) . "%\n\n";
        $aiMessage .= "Bulgular:\n" . implode("\n", $analysisResult['findings']) . "\n\n";
        $aiMessage .= "Öneriler:\n" . implode("\n", $analysisResult['recommendations']) . "\n\n";
        $aiMessage .= "⚠️ Bu analiz yalnızca bilgilendirme amaçlıdır. Kesin teşhis için mutlaka dermatoloji uzmanına başvurun.";
        
        // Save AI response
        $aiMessageId = $db->insert('chat_messages', [
            'conversation_id' => $conversationId,
            'user_id' => $userId,
            'message' => $aiMessage,
            'message_type' => 'ai',
            'diagnosis_result' => json_encode($analysisResult),
            'credits_used' => 2
        ]);
        
        // Deduct credits
        $db->update('users', [
            'credits' => 'credits - 2'
        ], 'id = ?', [$userId]);
        
        // Add credit transaction
        $db->insert('credit_transactions', [
            'user_id' => $userId,
            'amount' => -2,
            'transaction_type' => 'spent',
            'description' => 'Cilt analizi',
            'related_activity_id' => $analysisId
        ]);
        
        // Update conversation
        $db->update('chat_conversations', [
            'updated_at' => date('Y-m-d H:i:s')
        ], 'id = ?', [$conversationId]);
        
        // Log activity
        Utils::logActivity($userId, 'analysis', [
            'analysis_id' => $analysisId,
            'risk_level' => $riskLevel,
            'confidence' => $analysisResult['confidence']
        ]);
        
        // Send notification if high risk
        if ($riskLevel === 'high' || $riskLevel === 'critical') {
            $db->insert('notifications', [
                'user_id' => $userId,
                'title' => 'Acil Doktor Konsültasyonu',
                'message' => 'Cilt analiziniz yüksek risk gösteriyor. Lütfen en kısa sürede dermatoloji uzmanına başvurun.',
                'type' => 'warning'
            ]);
        }
        
        $db->commit();
        
        Utils::sendResponse([
            'analysis_id' => $analysisId,
            'conversation_id' => $conversationId,
            'image_path' => $imagePath,
            'analysis_result' => $analysisResult,
            'ai_message' => $aiMessage,
            'credits_used' => 2
        ]);
        
    } catch (Exception $e) {
        $db->rollback();
        Utils::sendError('Analiz başarısız: ' . $e->getMessage(), 500);
    }
}

function handleDeleteConversation($conversationId, $db) {
    $userId = Utils::getAuthUser();
    
    // Check if conversation belongs to user
    $conversation = $db->fetch("
        SELECT id FROM chat_conversations 
        WHERE id = ? AND user_id = ?
    ", [$conversationId, $userId]);
    
    if (!$conversation) {
        Utils::sendError('Konuşma bulunamadı', 404);
    }
    
    try {
        $db->beginTransaction();
        
        // Delete messages
        $db->delete('chat_messages', 'conversation_id = ?', [$conversationId]);
        
        // Update skin analyses
        $db->update('skin_analyses', [
            'conversation_id' => null
        ], 'conversation_id = ?', [$conversationId]);
        
        // Delete conversation
        $db->delete('chat_conversations', 'id = ?', [$conversationId]);
        
        $db->commit();
        
        Utils::sendResponse(['message' => 'Konuşma silindi']);
        
    } catch (Exception $e) {
        $db->rollback();
        Utils::sendError('Konuşma silinemedi: ' . $e->getMessage(), 500);
    }
}

function handleGetHistory($db) {
    $userId = Utils::getAuthUser();
    $page = (int)($_GET['page'] ?? 1);
    $limit = (int)($_GET['limit'] ?? 10);
    $offset = ($page - 1) * $limit;
    
    // Get skin analyses history
    $analyses = $db->fetchAll("
        SELECT 
            id, image_path, original_image_name, analysis_result,
            confidence_score, risk_level, recommendations,
            analysis_date,
            DATE_FORMAT(analysis_date, '%d.%m.%Y %H:%i') as formatted_date
        FROM skin_analyses 
        WHERE user_id = ? 
        ORDER BY analysis_date DESC 
        LIMIT ? OFFSET ?
    ", [$userId, $limit, $offset]);
    
    foreach ($analyses as &$analysis) {
        $analysis['analysis_result'] = json_decode($analysis['analysis_result'], true);
        $analysis['confidence_score'] = (float)$analysis['confidence_score'];
    }
    
    // Count total
    $countResult = $db->fetch("
        SELECT COUNT(*) as total FROM skin_analyses WHERE user_id = ?
    ", [$userId]);
    
    Utils::sendResponse([
        'analyses' => $analyses,
        'pagination' => [
            'current_page' => $page,
            'per_page' => $limit,
            'total' => (int)$countResult['total'],
            'total_pages' => ceil($countResult['total'] / $limit)
        ]
    ]);
}

?>