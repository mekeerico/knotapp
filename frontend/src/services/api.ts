/**
 * Resolves the backend API base URL for frontend requests.
 * Uses same-origin /api-backend proxy on production to bypass CORS and port 8080 firewall blocks.
 */
export function getApiUrl(): string {
  if (typeof window !== 'undefined') {
    const envUrl = process.env.NEXT_PUBLIC_API_URL;
    const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';

    // If in remote browser and env is missing, empty, or defaulted to localhost, route via Next.js proxy
    if (!isLocalhost && (!envUrl || envUrl.includes('localhost') || envUrl.includes('127.0.0.1'))) {
      return '/api-backend';
    }

    if (envUrl && envUrl.trim() !== '') {
      return envUrl.replace(/\/+$/, '');
    }

    if (isLocalhost) {
      return 'http://localhost:8080';
    }

    return '/api-backend';
  }

  // Server-side rendering
  return (process.env.INTERNAL_BACKEND_URL || 'http://backend-core:8080').replace(/\/+$/, '');
}
