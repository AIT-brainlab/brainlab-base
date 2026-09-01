document.addEventListener("DOMContentLoaded", () => {
    const dropZone = document.getElementById("dropZone");
    const fileInput = document.getElementById("fileInput");
    const dropContent = document.getElementById("dropContent");
    const fileInfo = document.getElementById("fileInfo");
    const fileName = document.getElementById("fileName");
    const fileSize = document.getElementById("fileSize");
    const removeFileBtn = document.getElementById("removeFileBtn");
    const printForm = document.getElementById("printForm");
    const submitBtn = document.getElementById("submitBtn");
    const btnText = document.getElementById("btnText");
    const btnIcon = document.getElementById("btnIcon");

    const colorRadios = document.querySelectorAll('input[name="color_mode"]');
    const colorWarning = document.getElementById("colorWarning");
    const colorConfirmed = document.getElementById("colorConfirmed");
    const printerRadios = document.querySelectorAll('input[name="printer"]');
    const colorSection = document.getElementById("colorSection");

    let selectedFile = null;

    // Drag & Drop Handlers
    dropZone.addEventListener("click", () => fileInput.click());

    ["dragenter", "dragover"].forEach(event => {
        dropZone.addEventListener(event, (e) => {
            e.preventDefault();
            dropZone.classList.add("border-indigo-500", "bg-indigo-950/20");
        });
    });

    ["dragleave", "drop"].forEach(event => {
        dropZone.addEventListener(event, (e) => {
            e.preventDefault();
            dropZone.classList.remove("border-indigo-500", "bg-indigo-950/20");
        });
    });

    dropZone.addEventListener("drop", (e) => {
        const files = e.dataTransfer.files;
        if (files.length > 0) handleFile(files[0]);
    });

    fileInput.addEventListener("change", (e) => {
        if (e.target.files.length > 0) handleFile(e.target.files[0]);
    });

    function handleFile(file) {
        if (!file.name.toLowerCase().endsWith(".pdf")) {
            alert("Please select a valid PDF file (.pdf)");
            return;
        }
        if (file.size > 25 * 1024 * 1024) {
            alert("File exceeds maximum allowed size of 25 MB.");
            return;
        }
        selectedFile = file;
        fileName.textContent = file.name;
        fileSize.textContent = (file.size / 1024).toFixed(1) + " KB";
        dropContent.classList.add("hidden");
        fileInfo.classList.remove("hidden");
        updateSubmitState();
    }

    removeFileBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        selectedFile = null;
        fileInput.value = "";
        dropContent.classList.remove("hidden");
        fileInfo.classList.add("hidden");
        updateSubmitState();
    });

    // Printer selection handling (HP Magnum is B&W only)
    printerRadios.forEach(radio => {
        radio.addEventListener("change", () => {
            if (radio.value === "magnum") {
                colorSection.classList.add("opacity-40", "pointer-events-none");
                document.querySelector('input[name="color_mode"][value="monochrome"]').checked = true;
                colorWarning.classList.add("hidden");
                colorConfirmed.checked = false;
            } else {
                colorSection.classList.remove("opacity-40", "pointer-events-none");
            }
            updateSubmitState();
        });
    });

    // Color warning toggle
    colorRadios.forEach(radio => {
        radio.addEventListener("change", () => {
            if (radio.value === "color") {
                colorWarning.classList.remove("hidden");
            } else {
                colorWarning.classList.add("hidden");
                colorConfirmed.checked = false;
            }
            updateSubmitState();
        });
    });

    colorConfirmed.addEventListener("change", updateSubmitState);

    function updateSubmitState() {
        if (!selectedFile) {
            submitBtn.disabled = true;
            btnText.textContent = "Select PDF to Print";
            return;
        }

        const isColor = document.querySelector('input[name="color_mode"]:checked')?.value === "color";
        if (isColor && !colorConfirmed.checked) {
            submitBtn.disabled = true;
            btnText.textContent = "Confirm Color Quota Warning Above";
            return;
        }

        submitBtn.disabled = false;
        btnText.textContent = "Submit Print Job";
    }

    // Submit print job via API
    printForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        if (!selectedFile) return;

        submitBtn.disabled = true;
        btnIcon.textContent = "⏳";
        btnText.textContent = "Sending to CSIM Print Server...";

        const formData = new FormData();
        formData.append("file", selectedFile);
        formData.append("printer", document.querySelector('input[name="printer"]:checked').value);
        formData.append("color_mode", document.querySelector('input[name="color_mode"]:checked').value);
        formData.append("duplex", document.getElementById("duplexSelect").value);
        formData.append("copies", document.getElementById("copiesInput").value);
        formData.append("page_range", document.getElementById("pageRangeInput").value);
        formData.append("color_confirmed", colorConfirmed.checked);

        try {
            const resp = await fetch("/api/print", {
                method: "POST",
                body: formData
            });
            const data = await resp.json();

            if (!resp.ok) {
                throw new Error(data.detail || "Print job failed");
            }

            alert(`🎉 Success!\n\n${data.message}\nEstimated charged pages: ${data.charged_pages_estimate}\nJob ID(s): ${data.jobs.join(", ")}`);
            selectedFile = null;
            fileInput.value = "";
            dropContent.classList.remove("hidden");
            fileInfo.classList.add("hidden");
            updateSubmitState();
            fetchQueueStatus();
        } catch (err) {
            alert(`❌ Error: ${err.message}`);
        } finally {
            btnIcon.textContent = "🖨️";
            updateSubmitState();
        }
    });

    // Queue Polling
    async function fetchQueueStatus() {
        const el = document.getElementById("ricohQueueText");
        if (!el) return;
        try {
            const resp = await fetch("/api/queue-status?queue=ricoh");
            const data = await resp.json();
            el.textContent = data.status || "Idle / No jobs";
        } catch (e) {
            el.textContent = "Queue status unavailable";
        }
    }

    // Directory Sync Handler
    const refreshMembersBtn = document.getElementById("refreshMembersBtn");
    const syncIcon = document.getElementById("syncIcon");
    const membersSyncStatus = document.getElementById("membersSyncStatus");

    refreshMembersBtn?.addEventListener("click", async () => {
        if (syncIcon) syncIcon.classList.add("animate-spin");
        if (membersSyncStatus) {
            membersSyncStatus.textContent = "Syncing...";
            membersSyncStatus.className = "text-amber-400 font-mono";
        }

        try {
            const resp = await fetch("/api/members/refresh", { method: "POST" });
            const data = await resp.json();
            if (data.success) {
                if (membersSyncStatus) {
                    membersSyncStatus.textContent = `${data.count} Members`;
                    membersSyncStatus.className = "text-emerald-400 font-mono";
                }
                alert(`✅ Directory Synced!\n\nLoaded ${data.count} member accounts from ${data.source}.\nLast updated: ${data.last_updated}`);
            } else {
                if (membersSyncStatus) {
                    membersSyncStatus.textContent = "Sync Warning";
                    membersSyncStatus.className = "text-rose-400 font-mono";
                }
                alert(`⚠️ Directory Sync: ${data.message}`);
            }
        } catch (err) {
            if (membersSyncStatus) {
                membersSyncStatus.textContent = "Failed";
                membersSyncStatus.className = "text-rose-400 font-mono";
            }
            alert(`❌ Error syncing directory: ${err.message}`);
        } finally {
            if (syncIcon) syncIcon.classList.remove("animate-spin");
        }
    });

    document.getElementById("refreshQueueBtn")?.addEventListener("click", fetchQueueStatus);
    fetchQueueStatus();
});
