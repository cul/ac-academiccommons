document.addEventListener('turbo:load', function() {
    const trigger = document.querySelector('.feedback-trigger');
    const modalElement = document.getElementById('feedbackModal');
    const frame = document.getElementById('feedbackFrame');

    if (trigger && modalElement && frame) {
        trigger.addEventListener('click', function(e) {
            e.preventDefault();
            
            const baseUrl = this.getAttribute('data-url');
            const contextUrl = encodeURIComponent(window.location.href);
            frame.src = `${baseUrl}?referer=${contextUrl}`;
            
            $(modalElement).modal('show');
        });

        $(modalElement).on('hidden.bs.modal', function () {
            frame.src = '';
        });
    }
});