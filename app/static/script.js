document.addEventListener('DOMContentLoaded', function() {
    const btn1 = document.getElementById('btn1');
    const btn2 = document.getElementById('btn2');
    const box = document.querySelector('.box');
    
    // Animation 1: Spin and Scale
    btn1.addEventListener('click', function() {
        // Remove any existing animation classes
        box.classList.remove('animate-spin-scale', 'animate-bounce-color');
        
        // Force a reflow to restart the animation
        void box.offsetWidth;
        
        // Add the animation class
        box.classList.add('animate-spin-scale');
        
        // Remove the class after animation completes
        setTimeout(() => {
            box.classList.remove('animate-spin-scale');
        }, 1000);
    });
    
    // Animation 2: Bounce and Color Change
    btn2.addEventListener('click', function() {
        // Remove any existing animation classes
        box.classList.remove('animate-spin-scale', 'animate-bounce-color');
        
        // Force a reflow to restart the animation
        void box.offsetWidth;
        
        // Add the animation class
        box.classList.add('animate-bounce-color');
        
        // Remove the class after animation completes
        setTimeout(() => {
            box.classList.remove('animate-bounce-color');
        }, 1000);
    });
});
