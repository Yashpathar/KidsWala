import { Injectable } from '@angular/core';
import { ApiService } from './api.service';

/** Separate API per master — matches CategoryController, SizeController, etc. */
@Injectable({ providedIn: 'root' })
export class CategoryApiService {
  constructor(private api: ApiService) {}
  list(companyId?: number) { return this.api.get<any>('/category', { companyId }); }
  getById(id: number) { return this.api.get<any>(`/category/${id}`); }
  create(body: unknown) { return this.api.post<any>('/category', body); }
  update(body: unknown) { return this.api.put<any>('/category', body); }
  delete(id: number) { return this.api.delete<any>(`/category/${id}`); }
}

@Injectable({ providedIn: 'root' })
export class SizeApiService {
  constructor(private api: ApiService) {}
  list(companyId?: number) { return this.api.get<any>('/size', { companyId }); }
  getById(id: number) { return this.api.get<any>(`/size/${id}`); }
  create(body: unknown) { return this.api.post<any>('/size', body); }
  update(body: unknown) { return this.api.put<any>('/size', body); }
  delete(id: number) { return this.api.delete<any>(`/size/${id}`); }
}

@Injectable({ providedIn: 'root' })
export class ColorApiService {
  constructor(private api: ApiService) {}
  list(companyId?: number) { return this.api.get<any>('/color', { companyId }); }
  getById(id: number) { return this.api.get<any>(`/color/${id}`); }
  create(body: unknown) { return this.api.post<any>('/color', body); }
  update(body: unknown) { return this.api.put<any>('/color', body); }
  delete(id: number) { return this.api.delete<any>(`/color/${id}`); }
}

@Injectable({ providedIn: 'root' })
export class ProductApiService {
  constructor(private api: ApiService) {}
  list(companyId?: number, branchId?: number) { return this.api.get<any>('/product', { companyId, branchId }); }
  getById(id: number) { return this.api.get<any>(`/product/${id}`); }
  getByCode(code: string) { return this.api.get<any>(`/product/code/${code}`); }
  create(body: unknown) { return this.api.post<any>('/product', body); }
  update(body: unknown) { return this.api.put<any>('/product', body); }
  delete(id: number) { return this.api.delete<any>(`/product/${id}`); }
  uploadImage(file: File) { return this.api.uploadFile<any>('/upload/image', file); }
}

@Injectable({ providedIn: 'root' })
export class RoleApiService {
  constructor(private api: ApiService) {}
  list() { return this.api.get<any>('/master/roles'); }
  getById(id: number) { return this.api.get<any>(`/master/roles/${id}`); }
  create(body: unknown) { return this.api.post<any>('/master/roles', body); }
  update(body: unknown) { return this.api.put<any>('/master/roles', body); }
  delete(id: number) { return this.api.delete<any>(`/master/roles/${id}`); }
}

/** Facade used by master-crud component */
@Injectable({ providedIn: 'root' })
export class MastersService {
  constructor(
    private category: CategoryApiService,
    private size: SizeApiService,
    private color: ColorApiService,
    private product: ProductApiService,
    private role: RoleApiService
  ) {}

  private svc(type: string) {
    const map: Record<string, CategoryApiService | SizeApiService | ColorApiService | ProductApiService | RoleApiService> = {
      category: this.category,
      size: this.size,
      color: this.color,
      product: this.product,
      role: this.role
    };
    return map[type];
  }

  list(type: string, companyId?: number) {
    return this.svc(type).list(companyId);
  }

  getById(type: string, id: number) {
    return this.svc(type).getById(id);
  }

  create(type: string, body: unknown) {
    return this.svc(type).create(body);
  }

  update(type: string, body: unknown) {
    return this.svc(type).update(body);
  }

  delete(type: string, id: number) {
    return this.svc(type).delete(id);
  }

  uploadImage(file: File) {
    return this.product.uploadImage(file);
  }
}
