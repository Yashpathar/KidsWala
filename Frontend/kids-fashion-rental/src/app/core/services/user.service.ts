import { Injectable } from '@angular/core';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class UserService {
  constructor(private api: ApiService) {}

  list(companyId?: number, branchId?: number) {
    return this.api.get<any>('/user', { companyId, branchId });
  }

  getById(id: number) {
    return this.api.get<any>(`/user/${id}`);
  }

  create(body: unknown) {
    return this.api.post<any>('/user', body);
  }

  update(body: unknown) {
    return this.api.put<any>('/user', body);
  }

  delete(id: number) {
    return this.api.delete<any>(`/user/${id}`);
  }
}
