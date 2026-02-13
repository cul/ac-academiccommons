document.addEventListener('DOMContentLoaded', function() {
    const trigger = document.querySelector('.feedback-trigger');
    const modalElement = document.getElementById('feedbackModal');
    const frame = document.getElementById('feedbackFrame');
    const closeBtn = modalElement ? modalElement.querySelector('.close') : null;

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

        const closeModal = function() {
            modalElement.style.display = 'none';
            modalElement.classList.remove('show');
            frame.src = '';
            document.body.style.overflow = '';
        };

        if (closeBtn) {
            closeBtn.addEventListener('click', closeModal);
        }

        window.addEventListener('click', function(e) {
            if (e.target === modalElement) {
                closeModal();
            }
        });
    }
});