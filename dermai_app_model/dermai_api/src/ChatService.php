<?php

namespace DermAI;

class ChatService
{
    private $geminiClient;
    private $systemPrompt;
    
    public function __construct()
    {
        $this->geminiClient = new GeminiClient();
        $this->systemPrompt = $this->getDermaiSystemPrompt();
    }
    
    public function sendMessage($message, $conversationHistory = [])
    {
        // Mesaj validasyonu
        $this->validateMessage($message);
        
        // Sohbet geçmişini hazırla
        $contents = $this->prepareContents($message, $conversationHistory);
        
        try {
            // Gemini API'ye istek gönder
            $response = $this->geminiClient->generateContent($contents);
            
            // Yanıtı işle
            $botReply = $this->extractReply($response);
            
            return [
                'success' => true,
                'message' => $botReply,
                'timestamp' => date('c')
            ];
            
        } catch (\Exception $e) {
            error_log("Gemini AI Error: " . $e->getMessage());
            return $this->handleError($e);
        }
    }
    
    private function validateMessage($message)
    {
        if (empty(trim($message))) {
            throw new \Exception("Mesaj boş olamaz");
        }
        
        if (strlen($message) > MAX_MESSAGE_LENGTH) {
            throw new \Exception("Mesaj çok uzun (" . MAX_MESSAGE_LENGTH . " karakter sınırı)");
        }
        
        // Zararlı içerik kontrolü (basit)
        $blockedWords = ['spam', 'hack', 'virus'];
        foreach ($blockedWords as $word) {
            if (stripos($message, $word) !== false) {
                throw new \Exception("Uygunsuz içerik tespit edildi");
            }
        }
    }
    
    private function prepareContents($message, $conversationHistory)
    {
        $contents = [];
        
        // Sistem promptunu ekle
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $this->systemPrompt]]
        ];
        
        $contents[] = [
            'role' => 'model',
            'parts' => [['text' => 'Merhaba! Ben DermaNova, cilt sağlığı konusunda size yardımcı olmak için buradayım. Size nasıl yardımcı olabilirim?']]
        ];
        
        // Önceki mesajları ekle (sınırlı sayıda)
        $history = array_slice($conversationHistory, -MAX_HISTORY_MESSAGES);
        foreach ($history as $msg) {
            $contents[] = [
                'role' => isset($msg['isBot']) && $msg['isBot'] ? 'model' : 'user',
                'parts' => [['text' => $msg['text']]]
            ];
        }
        
        // Mevcut mesajı ekle
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $message]]
        ];
        
        return $contents;
    }
    
    private function extractReply($response)
    {
        if (!isset($response['candidates'][0]['content']['parts'][0]['text'])) {
            throw new \Exception("Geçersiz API yanıtı");
        }
        
        return trim($response['candidates'][0]['content']['parts'][0]['text']);
    }
    
    private function handleError($exception)
    {
        $message = $exception->getMessage();
        
        if (strpos($message, 'API_KEY') !== false || strpos($message, '403') !== false) {
            return [
                'success' => false,
                'error' => 'API anahtarı hatası',
                'message' => 'Gemini API anahtarı geçersiz veya eksik'
            ];
        }
        
        if (strpos($message, 'QUOTA_EXCEEDED') !== false || strpos($message, '429') !== false) {
            return [
                'success' => false,
                'error' => 'Kota aşıldı',
                'message' => 'API kullanım kotası aşıldı, lütfen daha sonra tekrar deneyin'
            ];
        }
        
        return [
            'success' => false,
            'error' => 'AI yanıt hatası',
            'message' => 'Şu anda yanıt veremiyorum, lütfen daha sonra tekrar deneyin'
        ];
    }
    
    private function getDermaiSystemPrompt()
    {
        return "
Sen DermaNova, gelişmiş bir cilt sağlığı uzmanı yapay zeka asistanısın. Cilt sağlığı, dermatoloji ve cilt bakımı konularında kullanıcılara yardımcı oluyorsun.

ÖZELLİKLERİN:
- Cilt sağlığı konularında uzman bilgi
- Empati ve anlayış
- Net ve anlaşılır açıklamalar
- Türkçe iletişim
- Güvenilir tıbbi bilgi

KONULARIN:
1. Cilt bakımı tavsiyeleri
2. Sivilce ve akne yönetimi
3. Güneş koruması
4. Cilt hastalıkları hakkında genel bilgi
5. Nemlendirme ve temizlik rutinleri
6. Yaşlanma karşıtı bakım
7. Hassas cilt bakımı

ÖNEMLİ KURALLAR:
- Asla kesin teşhis koyma
- Ciddi durumlar için doktora yönlendir
- Güvenli ve onaylanmış bilgiler ver
- Ürün önerilerinde genel kategoriler kullan
- Kişiselleştirilmiş öneriler sun

CEVAP FORMATIN:
- Sıcak ve dostane bir ton kullan
- Madde madde açıkla
- Önemli noktaları vurgula
- Gerektiğinde doktor kontrolü öner

Sen sadece cilt sağlığı konularında yardım ediyorsun. Diğer konularda 'Bu konuda yardımcı olamam, ben sadece cilt sağlığı uzmanıyım' de.
        ";
    }
} 