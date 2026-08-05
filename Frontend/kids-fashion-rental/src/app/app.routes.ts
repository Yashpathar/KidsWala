import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { menuGuard } from './core/guards/menu.guard';
import { MasterConfig } from './pages/masters/master-crud/master-crud.component';

const categoryConfig: MasterConfig = {
  type: 'category',
  title: 'Category Master',
  idField: 'categoryID',
  columns: [
    { key: 'categoryID', label: 'ID' },
    { key: 'categoryName', label: 'Category Name' },
    { key: 'description', label: 'Description' },
    { key: 'isActive', label: 'Active' }
  ],
  fields: [
    { key: 'categoryName', label: 'Category Name', required: true },
    { key: 'description', label: 'Description', type: 'textarea' },
    { key: 'isActive', label: 'Active', type: 'checkbox' }
  ]
};

const sizeConfig: MasterConfig = {
  type: 'size',
  title: 'Size Master',
  idField: 'sizeID',
  columns: [
    { key: 'sizeID', label: 'ID' },
    { key: 'sizeName', label: 'Size' },
    { key: 'sizeCode', label: 'Code' },
    { key: 'sortOrder', label: 'Sort' },
    { key: 'isActive', label: 'Active' }
  ],
  fields: [
    { key: 'sizeName', label: 'Size Name', required: true },
    { key: 'sizeCode', label: 'Size Code' },
    { key: 'sortOrder', label: 'Sort Order', type: 'number' },
    { key: 'isActive', label: 'Active', type: 'checkbox' }
  ]
};

const colorConfig: MasterConfig = {
  type: 'color',
  title: 'Color Master',
  idField: 'colorID',
  columns: [
    { key: 'colorID', label: 'ID' },
    { key: 'colorName', label: 'Color Name' },
    { key: 'colorCode', label: 'Hex Code' },
    { key: 'isActive', label: 'Active' }
  ],
  fields: [
    { key: 'colorName', label: 'Color Name', required: true },
    { key: 'colorCode', label: 'Color Code (Hex)' },
    { key: 'isActive', label: 'Active', type: 'checkbox' }
  ]
};

export const routes: Routes = [
  { path: 'login', loadComponent: () => import('./pages/login/login.component').then(m => m.LoginComponent) },
  {
    path: '',
    loadComponent: () => import('./layout/main-layout/main-layout.component').then(m => m.MainLayoutComponent),
    canActivate: [authGuard],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', canActivate: [menuGuard('dashboard')], loadComponent: () => import('./pages/dashboard/dashboard.component').then(m => m.DashboardComponent) },
      { path: 'masters/category', canActivate: [menuGuard('category')], loadComponent: () => import('./pages/masters/master-crud/master-crud.component').then(m => m.MasterCrudComponent), data: { config: categoryConfig } },
      { path: 'masters/size', canActivate: [menuGuard('size')], loadComponent: () => import('./pages/masters/master-crud/master-crud.component').then(m => m.MasterCrudComponent), data: { config: sizeConfig } },
      { path: 'masters/color', canActivate: [menuGuard('color')], loadComponent: () => import('./pages/masters/master-crud/master-crud.component').then(m => m.MasterCrudComponent), data: { config: colorConfig } },
      { path: 'masters/product', canActivate: [menuGuard('product')], loadComponent: () => import('./pages/masters/product-master/product-master.component').then(m => m.ProductMasterComponent) },
      { path: 'masters/add-product', canActivate: [menuGuard('product')], loadComponent: () => import('./pages/masters/add-product/add-product.component').then(m => m.AddProductComponent) },
      { path: 'masters/edit-product/:id', canActivate: [menuGuard('product')], loadComponent: () => import('./pages/masters/add-product/add-product.component').then(m => m.AddProductComponent) },
      { path: 'masters/company', canActivate: [menuGuard('company')], loadComponent: () => import('./pages/masters/company-master/company-master.component').then(m => m.CompanyMasterComponent) },
      { path: 'masters/branch', canActivate: [menuGuard('branch')], loadComponent: () => import('./pages/masters/branch-master/branch-master.component').then(m => m.BranchMasterComponent) },
      { path: 'masters/role-rights', canActivate: [menuGuard('roleRights')], loadComponent: () => import('./pages/masters/role-rights/role-rights.component').then(m => m.RoleRightsComponent) },
      { path: 'booking/add', canActivate: [menuGuard('bookingAdd')], loadComponent: () => import('./pages/booking/add-booking/add-booking.component').then(m => m.AddBookingComponent) },
      { path: 'booking/list', canActivate: [menuGuard('bookingList')], loadComponent: () => import('./pages/booking/booking-list/booking-list.component').then(m => m.BookingListComponent) },
      { path: 'reports', canActivate: [menuGuard('reportBooking')], loadComponent: () => import('./pages/reports/reports-hub/reports-hub.component').then(m => m.ReportsHubComponent) },
      { path: 'reports/delivery', canActivate: [menuGuard('reportDelivery')], loadComponent: () => import('./pages/reports/delivery-report/delivery-report.component').then(m => m.DeliveryReportComponent) },
      { path: 'reports/return', canActivate: [menuGuard('reportReturn')], loadComponent: () => import('./pages/reports/return-report/return-report.component').then(m => m.ReturnReportComponent) },
      { path: 'reports/payments', canActivate: [menuGuard('reportPayment')], loadComponent: () => import('./pages/reports/payment-report/payment-report.component').then(m => m.PaymentReportComponent) },
      { path: 'invoice/:id', loadComponent: () => import('./pages/invoice/invoice.component').then(m => m.InvoiceComponent) }
    ]
  },
  { path: '**', redirectTo: 'dashboard' }
];
