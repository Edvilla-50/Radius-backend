<?php
$data = json_decode(file_get_contents('php://input'), true);

$userId = $data['userId'] ?? null;
$html = $data['html'] ?? null;

if(!$userId || $html == null){
    http_response_code(400);
    echo ",issing userId or html";
    exit;
}

$backend = "http://localhost:8080";//change when we find a host

$ch = curl_init("$backend/user/$userId/profile-html");
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PUT");
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(["html" => $html]));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Content-Type: application/json"
]);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
http_response_code($httpCode ?: 200);
echo $response;