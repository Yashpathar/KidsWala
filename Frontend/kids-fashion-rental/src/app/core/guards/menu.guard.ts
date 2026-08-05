import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
/** Block route when role has no view access for that menu key */
export const menuGuard = (menuKey: string): CanActivateFn => () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  if (auth.canViewMenu(menuKey)) return true;
  router.navigate([auth.getDashboardRoute()]);
  return false;
};
