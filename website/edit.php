<?php
$userId = $_GET['id'] ?? null;
if (!$userId) {
    http_response_code(400);
    echo "Missing user id";
    exit;
}

// call backend to get current HTML
$backend = "http://localhost:8080"; // change when hosted
$response = file_get_contents("$backend/user/$userId/profile-html");
$data = json_decode($response, true);
$currentHtml = $data["html"] ?? "<html><body><h1>New Profile</h1></body></html>";
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Radius Profile Builder</title>

    <!-- Tailwind -->
    <script src="https://cdn.tailwindcss.com"></script>

    <!-- CodeMirror -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.13/codemirror.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.13/codemirror.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.13/mode/xml/xml.min.js"></script>

</head>
<body class="bg-gray-900 text-white">
<div class="flex flex-col h-screen">

    <!-- Top bar -->
    <div class="flex items-center justify-between px-6 py-4 bg-gray-800 shadow">
        <h1 class="text-xl font-bold text-green-400">Radius Profile Builder</h1>
        <div class="flex gap-3">
            <button id="templateMinimal" class="px-3 py-1 bg-gray-700 rounded hover:bg-gray-600 text-sm">
                Minimal
            </button>
            <button id="templateDark" class="px-3 py-1 bg-gray-700 rounded hover:bg-gray-600 text-sm">
                Dark
            </button>
            <button id="templateGamer" class="px-3 py-1 bg-gray-700 rounded hover:bg-gray-600 text-sm">
                Gamer
            </button>
            <button id="saveBtn" class="px-4 py-2 bg-green-500 rounded hover:bg-green-400 text-sm font-semibold">
                Save
            </button>
        </div>
    </div>

    <!-- Main content -->
    <div class="flex flex-1 overflow-hidden">

        <!-- Editor -->
        <div class="w-1/2 h-full border-r border-gray-700">
            <textarea id="editor"><?= htmlspecialchars($currentHtml) ?></textarea>
        </div>

        <!-- Preview -->
        <div class="w-1/2 h-full bg-white">
            <iframe id="preview" class="w-full h-full border-0"></iframe>
        </div>

    </div>
</div>

<script>
    const USER_ID = <?= (int)$userId ?>;
</script>
<script src="js/editor.js"></script>
</body>
</html>
