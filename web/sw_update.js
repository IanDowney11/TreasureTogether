// Service Worker Update Handler for TreasureTogether PWA
(function() {
  'use strict';

  // Check if service workers are supported
  if (!('serviceWorker' in navigator)) {
    console.log('Service Workers not supported');
    return;
  }

  let refreshing = false;

  // Detect controller change and refresh page
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (refreshing) return;
    refreshing = true;
    console.log('New service worker activated, reloading page...');
    window.location.reload();
  });

  // Function to check for updates
  function checkForUpdates() {
    navigator.serviceWorker.getRegistration().then(reg => {
      if (!reg) return;

      // Check for updates
      reg.update().then(() => {
        console.log('Checked for service worker updates');
      });
    });
  }

  // Listen for new service worker waiting
  navigator.serviceWorker.ready.then(registration => {
    // Check for updates every 60 seconds
    setInterval(() => {
      checkForUpdates();
    }, 60000);

    // Show update prompt if new service worker is waiting
    if (registration.waiting) {
      showUpdatePrompt(registration.waiting);
    }

    registration.addEventListener('updatefound', () => {
      const newWorker = registration.installing;

      newWorker.addEventListener('statechange', () => {
        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
          // New service worker available
          showUpdatePrompt(newWorker);
        }
      });
    });
  });

  // Show update prompt to user
  function showUpdatePrompt(worker) {
    // Create update banner
    const banner = document.createElement('div');
    banner.id = 'update-banner';
    banner.style.cssText = `
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      background: #2196F3;
      color: white;
      padding: 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      box-shadow: 0 -2px 10px rgba(0,0,0,0.2);
      z-index: 10000;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    `;

    banner.innerHTML = `
      <div>
        <strong>Update Available!</strong>
        <p style="margin: 4px 0 0 0; font-size: 14px;">
          A new version of TreasureTogether is ready to install.
        </p>
      </div>
      <div>
        <button id="update-button" style="
          background: white;
          color: #2196F3;
          border: none;
          padding: 8px 16px;
          border-radius: 4px;
          font-weight: bold;
          cursor: pointer;
          margin-right: 8px;
        ">Update Now</button>
        <button id="dismiss-button" style="
          background: transparent;
          color: white;
          border: 1px solid white;
          padding: 8px 16px;
          border-radius: 4px;
          cursor: pointer;
        ">Later</button>
      </div>
    `;

    document.body.appendChild(banner);

    // Update button handler
    document.getElementById('update-button').addEventListener('click', () => {
      worker.postMessage({ type: 'SKIP_WAITING' });
      banner.remove();
    });

    // Dismiss button handler
    document.getElementById('dismiss-button').addEventListener('click', () => {
      banner.remove();
    });
  }

  console.log('Service Worker update detection initialized');
})();
