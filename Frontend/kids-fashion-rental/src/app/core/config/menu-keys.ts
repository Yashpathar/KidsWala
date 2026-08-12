/** Menu keys — must match tblRoleRights.MenuKey and backend SP seeds */
export interface AppMenuDef {
  key: string;
  label: string;
  route?: string;
}

export const APP_MENUS: AppMenuDef[] = [
  { key: 'dashboard', label: 'Dashboard', route: '/dashboard' },
  { key: 'category', label: 'Category Master', route: '/masters/category' },
  { key: 'size', label: 'Size Master', route: '/masters/size' },
  { key: 'color', label: 'Color Master', route: '/masters/color' },
  { key: 'product', label: 'Product Master', route: '/masters/product' },
  { key: 'company', label: 'Company Master', route: '/masters/company' },
  { key: 'branch', label: 'Branch Master', route: '/masters/branch' },
  { key: 'user', label: 'User Master', route: '/masters/user' },
  { key: 'roleRights', label: 'Role Rights', route: '/masters/role-rights' },
  { key: 'bookingAdd', label: 'Add Booking', route: '/booking/add' },
  { key: 'bookingList', label: 'Booking List', route: '/booking/list' },
  { key: 'reportDelivery', label: 'Today Delivery', route: '/reports/delivery' },
  { key: 'reportReturn', label: 'Today Return', route: '/reports/return' },
  { key: 'reportBooking', label: 'Booking Report', route: '/reports' },
  { key: 'reportPayment', label: 'Payment Report', route: '/reports/payments' }
];

export const ROUTE_MENU_MAP: Record<string, string> = {
  '/masters/add-product': 'product'
};
for (const m of APP_MENUS) {
  if (m.route) ROUTE_MENU_MAP[m.route] = m.key;
}
