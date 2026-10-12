document.addEventListener('click', function(e) {
    const trigger = e.target.closest('.feedback-trigger');
    if (!trigger) return;

    e.preventDefault();

    const modalElement = document.getElementById('feedbackModal');
    const frame = document.getElementById('feedbackFrame');
    if (!modalElement || !frame) return;

    const url = new URL(trigger.dataset.url);
    url.searchParams.set('submitted_from_page', window.location.origin + window.location.pathname);
    url.searchParams.set('window_width', window.innerWidth);
    url.searchParams.set('window_height', window.innerHeight);
    frame.src = url.toString();

    $(modalElement).modal('show');
});

$(document).on('hidden.bs.modal', '#feedbackModal', function() {
    const frame = document.getElementById('feedbackFrame');
    if (frame) frame.src = '';
});

