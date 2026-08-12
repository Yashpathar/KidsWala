import { environment } from '../../../environments/environment';

export const DEFAULT_PRODUCT_IMAGE = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 24 24" fill="none" stroke="%2394a3b8" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="background:%23f1f5f9;border-radius:8px"><path d="M20.38 3.46L16 2a4 4 0 0 0-8 0L3.62 3.46a2 2 0 0 0-1.34 2.23l.58 3.47a1 1 0 0 0 .99.84H6v10a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V10h2.15a1 1 0 0 0 .99-.84l.58-3.47a2 2 0 0 0-1.34-2.23z"/></svg>`;

export const DEFAULT_LOGO_IMAGE = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 24 24" fill="none" stroke="%236366f1" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="background:%23eef2ff;border-radius:8px"><path d="M3 21h18"/><path d="M9 8h1"/><path d="M9 12h1"/><path d="M9 16h1"/><path d="M14 8h1"/><path d="M14 12h1"/><path d="M14 16h1"/><path d="M5 21V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16"/></svg>`;

export function getImageUrl(path?: string, type: 'product' | 'logo' = 'product'): string {
  if (!path || !path.trim()) {
    return type === 'logo' ? DEFAULT_LOGO_IMAGE : DEFAULT_PRODUCT_IMAGE;
  }
  if (path.startsWith('http') || path.startsWith('data:')) {
    return path;
  }
  const base = environment.apiUrl.replace(/\/api\/?$/, '');
  return `${base}${path.startsWith('/') ? path : '/' + path}`;
}

export function handleImageError(event: Event, type: 'product' | 'logo' = 'product'): void {
  const imgElement = event.target as HTMLImageElement;
  if (imgElement) {
    imgElement.src = type === 'logo' ? DEFAULT_LOGO_IMAGE : DEFAULT_PRODUCT_IMAGE;
  }
}
