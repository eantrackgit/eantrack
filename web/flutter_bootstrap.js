{{flutter_js}}
{{flutter_build_config}}

const EANTRACK_CACHE_CLEANUP_RELOAD_KEY = 'eantrack-cache-cleanup-reload-v1';
const EANTRACK_LEGACY_CACHE_PATTERNS = [
  /^flutter-app-cache$/,
  /^flutter-temp-cache$/,
  /^flutter-app-manifest$/,
  /^workbox-precache/i,
  /^eantrack-/i,
];

function isControlledByCurrentPage(registration) {
  return window.location.href.startsWith(registration.scope);
}

function getRegistrationScriptUrls(registration) {
  return [
    registration.active?.scriptURL,
    registration.waiting?.scriptURL,
    registration.installing?.scriptURL,
  ].filter(Boolean);
}

function isLegacyFlutterRegistration(registration) {
  return (
    isControlledByCurrentPage(registration) &&
    getRegistrationScriptUrls(registration).some((scriptUrl) =>
      scriptUrl.includes('flutter_service_worker.js')
    )
  );
}

async function clearLegacyServiceWorkersAndCaches() {
  let shouldReload = false;

  if ('serviceWorker' in navigator) {
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      const legacyRegistrations = registrations.filter(isLegacyFlutterRegistration);
      if (legacyRegistrations.length > 0) {
        await Promise.all(
          legacyRegistrations.map((registration) => registration.unregister())
        );
        shouldReload = true;
      }
    } catch (error) {
      console.warn('Failed to unregister legacy Flutter service workers.', error);
    }
  }

  if ('caches' in window) {
    try {
      const cacheKeys = await window.caches.keys();
      const legacyCacheKeys = cacheKeys.filter((cacheKey) =>
        EANTRACK_LEGACY_CACHE_PATTERNS.some((pattern) => pattern.test(cacheKey))
      );
      if (legacyCacheKeys.length > 0) {
        await Promise.all(
          legacyCacheKeys.map((cacheKey) => window.caches.delete(cacheKey))
        );
        shouldReload = true;
      }
    } catch (error) {
      console.warn('Failed to clear legacy Flutter caches.', error);
    }
  }

  if (shouldReload) {
    if (sessionStorage.getItem(EANTRACK_CACHE_CLEANUP_RELOAD_KEY) !== 'done') {
      sessionStorage.setItem(EANTRACK_CACHE_CLEANUP_RELOAD_KEY, 'done');
      window.location.reload();
      return false;
    }
  }

  sessionStorage.removeItem(EANTRACK_CACHE_CLEANUP_RELOAD_KEY);
  return true;
}

(async function bootstrapFlutterApp() {
  const shouldStartApp = await clearLegacyServiceWorkersAndCaches();
  if (!shouldStartApp) {
    return;
  }

  await _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine({
        useColorEmoji: true,
      });
      await appRunner.runApp();
    },
  });
})();
