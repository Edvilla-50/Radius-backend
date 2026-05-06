// init CodeMirror
const editor = CodeMirror.fromTextArea(document.getElementById("editor"), {
    mode: "xml",
    theme: "default",
    lineNumbers: true,
    tabSize: 2,
    lineWrapping: true
});

const preview = document.getElementById("preview");
const saveBtn = document.getElementById("saveBtn");

// live preview
function updatePreview() {
    preview.srcdoc = editor.getValue();
}
editor.on("change", updatePreview);
updatePreview();

// templates
const templates = {
    minimal: `
<html>
  <body style="font-family: Arial; background: white; padding: 20px;">
    <h1 style="color: #333;">My Profile</h1>
    <p style="color: #666;">This is my bio.</p>
    <blockquote style="color: #999; font-style: italic;">"Favorite quote here."</blockquote>
  </body>
</html>`,
    dark: `
<html>
  <body style="font-family: Arial; background: #1a1a2e; padding: 20px; color: white;">
    <h1 style="color: #e94560;">My Profile</h1>
    <p style="color: #ccc;">This is my bio.</p>
    <blockquote style="color: #e94560; font-style: italic;">"Favorite quote here."</blockquote>
  </body>
</html>`,
    gamer: `
<html>
  <body style="font-family: 'Courier New'; background: #0d0d0d; padding: 20px; color: #00ff00;">
    <h1 style="color: #00ff00; text-shadow: 0 0 10px #00ff00;">My Profile</h1>
    <p style="color: #00cc00;">This is my bio.</p>
    <blockquote style="color: #ff00ff; font-style: italic;">"Favorite quote here."</blockquote>
  </body>
</html>`
};

document.getElementById("templateMinimal").onclick = () => {
    editor.setValue(templates.minimal.trim());
    updatePreview();
};
document.getElementById("templateDark").onclick = () => {
    editor.setValue(templates.dark.trim());
    updatePreview();
};
document.getElementById("templateGamer").onclick = () => {
    editor.setValue(templates.gamer.trim());
    updatePreview();
};

// save
saveBtn.onclick = async () => {
    const html = editor.getValue();

    const res = await fetch("api/updateProfile.php", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId: USER_ID, html })
    });

    if (res.ok) {
        alert("Profile saved!");
        await reloadFromBackend();
    } else {
        alert("Failed to save profile");
    }
};
async function reloadFromBackend() {
    const res = await fetch(`api/getProfile.php?id=${USER_ID}`);
    const data = await res.json();
    editor.setValue(data.html);
    updatePreview();
}

