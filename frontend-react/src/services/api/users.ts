import { api } from './client'

// ================== USER API ==================

export interface User {
  id: string
  username: string
  name: string
  email: string
  role: string
  isActive: boolean
  lastLogin?: string
  createdAt: string
}

export interface UserDetail extends User {
  workerId?: string
  workerName?: string
  defaultBranchId?: string
  defaultBranchName?: string
  isLocked?: boolean
  lastLoginAt?: string
  mustChangePassword?: boolean
  roles?: string[]
  permissions?: string[]
}

export interface UserCreateRequest {
  username: string
  email: string
  password: string
  fullName?: string
  roleId?: string
  branchId?: string
}

export interface UserUpdateRequest {
  email?: string
  fullName?: string
  roleId?: string
  branchId?: string
  active?: boolean
}

export interface ChangePasswordRequest {
  newPassword: string
}

export const userApi = {
  list: async (): Promise<UserDetail[]> => {
    const response = await api.get<UserDetail[]>('/users')
    return response.data
  },
  getById: async (id: string): Promise<UserDetail> => {
    const response = await api.get<UserDetail>(`/users/${id}`)
    return response.data
  },
  getCurrentUser: async (): Promise<UserDetail> => {
    const response = await api.get<UserDetail>('/users/me')
    return response.data
  },
  create: async (data: UserCreateRequest): Promise<UserDetail> => {
    const response = await api.post<UserDetail>('/users', data)
    return response.data
  },
  update: async (id: string, data: UserUpdateRequest): Promise<UserDetail> => {
    const response = await api.put<UserDetail>(`/users/${id}`, data)
    return response.data
  },
  changePassword: async (id: string, newPassword: string): Promise<void> => {
    await api.post(`/users/${id}/change-password`, { newPassword })
  },
  toggleActive: async (id: string): Promise<UserDetail> => {
    const response = await api.post<UserDetail>(`/users/${id}/toggle-active`)
    return response.data
  },
  archive: async (id: string): Promise<void> => {
    await api.post(`/users/${id}/archive`)
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/users/${id}`)
  },
  updatePassword: async (oldPassword: string, newPassword: string): Promise<void> => {
    await api.put('/users/me/password', { oldPassword, newPassword })
  }
}

// ================== PERMISSION API ==================

export interface Permission {
  id: string
  code: string
  name: string
  description?: string
  module: string
  isSystemPermission: boolean
  isActive: boolean
  createdAt: string
}

export interface PermissionCreateRequest {
  code: string
  name: string
  description?: string
  module: string
  isSystemPermission?: boolean
  isActive?: boolean
}

export const permissionApi = {
  list: async (): Promise<Permission[]> => {
    const response = await api.get<Permission[]>('/permissions')
    return response.data
  },
  getActive: async (): Promise<Permission[]> => {
    const response = await api.get<Permission[]>('/permissions/active')
    return response.data
  },
  getByModule: async (module: string): Promise<Permission[]> => {
    const response = await api.get<Permission[]>(`/permissions/module/${module}`)
    return response.data
  },
  getById: async (id: string): Promise<Permission> => {
    const response = await api.get<Permission>(`/permissions/${id}`)
    return response.data
  },
  create: async (data: PermissionCreateRequest): Promise<Permission> => {
    const response = await api.post<Permission>('/permissions', data)
    return response.data
  },
  update: async (id: string, data: Partial<PermissionCreateRequest>): Promise<Permission> => {
    const response = await api.put<Permission>(`/permissions/${id}`, data)
    return response.data
  },
  toggleActive: async (id: string): Promise<Permission> => {
    const response = await api.post<Permission>(`/permissions/${id}/toggle-active`)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/permissions/${id}`)
  }
}

// ================== ROLE API ==================

export interface Role {
  id: string
  code: string
  name: string
  description?: string
  roleType: string
  hierarchyLevel?: number
  isSystemRole: boolean
  isActive: boolean
  permissions: string[] // Permission names (not IDs)
}

export interface RoleCreateRequest {
  code: string
  name: string
  description?: string
  permissionIds?: string[]
}

export interface RoleUpdateRequest {
  name?: string
  description?: string
  active?: boolean
  permissionIds?: string[]
}

export const roleApi = {
  list: async (): Promise<Role[]> => {
    const response = await api.get<Role[]>('/roles')
    return response.data
  },
  getById: async (id: string): Promise<Role> => {
    const response = await api.get<Role>(`/roles/${id}`)
    return response.data
  },
  create: async (data: RoleCreateRequest): Promise<Role> => {
    const response = await api.post<Role>('/roles', data)
    return response.data
  },
  update: async (id: string, data: RoleUpdateRequest): Promise<Role> => {
    const response = await api.put<Role>(`/roles/${id}`, data)
    return response.data
  },
  addPermission: async (roleId: string, permissionId: string): Promise<Role> => {
    const response = await api.post<Role>(`/roles/${roleId}/permissions/${permissionId}`)
    return response.data
  },
  removePermission: async (roleId: string, permissionId: string): Promise<void> => {
    await api.delete(`/roles/${roleId}/permissions/${permissionId}`)
  },
  toggleActive: async (id: string): Promise<Role> => {
    const response = await api.post<Role>(`/roles/${id}/toggle-active`)
    return response.data
  },
  delete: async (id: string): Promise<void> => {
    await api.delete(`/roles/${id}`)
  }
}
