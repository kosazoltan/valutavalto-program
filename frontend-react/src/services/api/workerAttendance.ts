import { api } from './client'

// ========== Types ==========

export interface WorkerAttendanceDto {
    id: string
    workerId: number
    workerName?: string
    branchId?: string
    branchCode?: string
    loginAt: string   // ISO datetime
    logoutAt?: string
    ipAddress?: string
    userAgent?: string
    sessionToken?: string
    // Computed (frontend)
    durationMinutes?: number
}

export interface PagedAttendance {
    content: WorkerAttendanceDto[]
    totalElements: number
    totalPages: number
    pageable: { pageNumber: number; pageSize: number }
}

// ========== API ==========

export const workerAttendanceApi = {
    /**
     * Bejelentkezés rögzítése a bejelentkezett workerhez.
     */
    login: async (): Promise<WorkerAttendanceDto> => {
        const r = await api.post<WorkerAttendanceDto>('/attendance/login')
        return r.data
    },

    /**
     * Nyitott jelenléti session lezárása.
     */
    logout: async (attendanceId: string): Promise<WorkerAttendanceDto> => {
        const r = await api.post<WorkerAttendanceDto>(`/attendance/${attendanceId}/logout`)
        return r.data
    },

    /**
     * Bejelentkezett worker sajat naploja.
     */
    my: async (from?: string, to?: string, page = 0, size = 50): Promise<PagedAttendance> => {
        const r = await api.get<PagedAttendance>('/attendance/my', {
            params: { from, to, page, size },
            _preservePaged: true,
        } as Record<string, unknown>)
        return r.data
    },

    /**
     * Adott worker (csapattag) naploja. SUPERVISOR+ jog.
     */
    byWorker: async (workerId: number, from?: string, to?: string, page = 0, size = 50): Promise<PagedAttendance> => {
        const r = await api.get<PagedAttendance>(`/attendance/worker/${workerId}`, {
            params: { from, to, page, size },
            _preservePaged: true,
        } as Record<string, unknown>)
        return r.data
    },
}

// ========== Helper ==========

/**
 * Kiszamitja a bejelentkezes idotartamat percekben.
 * Ha meg nincs logoutAt (active session), a now-t hasznalja.
 */
export function calculateDuration(a: WorkerAttendanceDto): number {
    const start = new Date(a.loginAt).getTime()
    const end = a.logoutAt ? new Date(a.logoutAt).getTime() : Date.now()
    return Math.max(0, Math.round((end - start) / 60000))
}

export function formatDuration(minutes: number): string {
    if (minutes < 60) return `${minutes} perc`
    const h = Math.floor(minutes / 60)
    const m = minutes % 60
    return m === 0 ? `${h} ora` : `${h} ora ${m} perc`
}
