<?php

namespace DermAI;

class GeminiClient
{
    private $apiKey;
    private $apiUrl;
    
    public function __construct($apiKey = null)
    {
        $this->apiKey = $apiKey ?: GEMINI_API_KEY;
        $this->apiUrl = GEMINI_API_URL;
    }
    
    public function generateContent($contents, $config = [])
    {
        $defaultConfig = [
            'temperature' => 0.7,
            'topK' => 40,
            'topP' => 0.95,
            'maxOutputTokens' => 1024
        ];
        
        $generationConfig = array_merge($defaultConfig, $config);
        
        $payload = [
            'contents' => $contents,
            'generationConfig' => $generationConfig,
            'safetySettings' => [
                [
                    'category' => 'HARM_CATEGORY_HARASSMENT',
                    'threshold' => 'BLOCK_MEDIUM_AND_ABOVE'
                ],
                [
                    'category' => 'HARM_CATEGORY_HATE_SPEECH',
                    'threshold' => 'BLOCK_MEDIUM_AND_ABOVE'
                ],
                [
                    'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                    'threshold' => 'BLOCK_MEDIUM_AND_ABOVE'
                ],
                [
                    'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT',
                    'threshold' => 'BLOCK_MEDIUM_AND_ABOVE'
                ]
            ]
        ];
        
        return $this->makeRequest($payload);
    }
    
    private function makeRequest($payload)
    {
        $url = $this->apiUrl . '?key=' . $this->apiKey;
        
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode($payload),
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'User-Agent: DermAI-ChatBot/1.0'
            ],
            CURLOPT_TIMEOUT => 30,
            CURLOPT_SSL_VERIFYPEER => true
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        
        if ($error) {
            throw new \Exception("cURL Error: " . $error);
        }
        
        if ($httpCode !== 200) {
            throw new \Exception("HTTP Error: " . $httpCode . " - " . $response);
        }
        
        $decoded = json_decode($response, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new \Exception("JSON Decode Error: " . json_last_error_msg());
        }
        
        return $decoded;
    }
} 