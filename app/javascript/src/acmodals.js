document.addEventListener('DOMContentLoaded', function() {
    const trigger = document.querySelector('.feedback-trigger');
    const modal = document.getElementById('feedbackModal');
    const frame = document.getElementById('feedbackFrame');
    const closeBtn = document.getElementById('closeModal');

    if (trigger && modal && frame) {
        
        trigger.addEventListener('click', function(e) {
            e.preventDefault();
            
            const baseUrl = this.getAttribute('href');
            const contextUrl = encodeURIComponent(window.location.href);
            
            frame.src = `${baseUrl}?referer=${contextUrl}`;
            modal.style.display = 'block';
            
            document.body.style.overflow = 'hidden';
        });

        const closeModal = function() {
            modal.style.display = 'none';
            frame.src = '';
            document.body.style.overflow = '';
        };

        if (closeBtn) {
            closeBtn.addEventListener('click', closeModal);
        }

        window.addEventListener('click', function(e) {
            if (e.target === modal) {
                closeModal();
            }
        });
    }
});