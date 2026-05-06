<?php
$userId = $_GET['id'] ?? null;
if(!$userId){
    http_response_code(400);
    echo "Missing id";
    exit;
}

$backend = "http://localhost:8080";

$response = file_get_contents("$backend/user/$userId/profile-html");
http_response_code(200);
echo $response;
