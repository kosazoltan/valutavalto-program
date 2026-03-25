import { useState, useEffect, useCallback } from 'react'
import { api } from '@/services/api/index'

export interface PoliticallyExposedPerson {
  id: number
  customerId: string
  customerName: string
  documentNumber: string
  pepCategory: string
  positionType: string
  positionDescription?: string
  country: string
  appointmentStartDate?: string
  appointmentEndDate?: string
  sourceOfWealth?: string
  sourceOfFunds?: string
  requiresEdd: boolean
  requiresApproval: boolean
  maxAmountWithoutApproval?: number
  reviewDate?: string
  notes?: string
  isActive: boolean
  createdAt: string
}

export interface PepFormData {
  customerId: string
  customerName: string
  documentNumber: string
  pepCategory: string
  positionType: string
  positionDescription: string
  country: string
  appointmentStartDate: string
  appointmentEndDate: string
  sourceOfWealth: string
  sourceOfFunds: string
  requiresEdd: boolean
  requiresApproval: boolean
  maxAmountWithoutApproval: string
  reviewDate: string
  notes: string
  isActive: boolean
}

export function usePepData() {
  const [pepList, setPepList] = useState<PoliticallyExposedPerson[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('active')
  const [reviewDue, setReviewDue] = useState<PoliticallyExposedPerson[]>([])

  const loadPepList = useCallback(async () => {
    setLoading(true)
    try {
      let response
      if (activeTab === 'active') {
        response = await api.get('/pep/active')
      } else if (activeTab === 'direct') {
        response = await api.get('/pep/category/DIRECT')
      } else if (activeTab === 'family') {
        response = await api.get('/pep/category/FAMILY')
      } else if (activeTab === 'associate') {
        response = await api.get('/pep/category/ASSOCIATE')
      } else {
        response = await api.get('/pep')
      }
      setPepList(response?.data || [])
    } catch {
      setPepList([])
    } finally {
      setLoading(false)
    }
  }, [activeTab])

  const loadReviewDue = useCallback(async () => {
    try {
      const response = await api.get('/pep/review-due')
      setReviewDue(response?.data || [])
    } catch {
      setReviewDue([])
    }
  }, [])

  useEffect(() => {
    void loadPepList()
    void loadReviewDue()
  }, [loadPepList, loadReviewDue])

  const savePep = useCallback(async (
    formData: PepFormData,
    editingPep: PoliticallyExposedPerson | null,
  ) => {
    const payload = {
      ...formData,
      appointmentStartDate: formData.appointmentStartDate ? formData.appointmentStartDate + 'T00:00:00' : null,
      appointmentEndDate: formData.appointmentEndDate ? formData.appointmentEndDate + 'T00:00:00' : null,
      reviewDate: formData.reviewDate ? formData.reviewDate + 'T00:00:00' : null,
      maxAmountWithoutApproval: formData.maxAmountWithoutApproval
        ? parseFloat(formData.maxAmountWithoutApproval)
        : null,
    }

    if (editingPep) {
      await api.put(`/pep/${editingPep.id}`, payload)
    } else {
      await api.post('/pep', payload)
    }
    void loadPepList()
  }, [loadPepList])

  return {
    pepList,
    loading,
    activeTab,
    setActiveTab,
    reviewDue,
    savePep,
  }
}
