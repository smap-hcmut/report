import { useState } from 'react'
import { authService } from '@/lib/api/services/auth.service'

interface UseRegisterReturn {
  register: (email: string, password: string) => Promise<void>
  isLoading: boolean
  error: string | null
  isSuccess: boolean
}

export const useRegister = (): UseRegisterReturn => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isSuccess, setIsSuccess] = useState(false)

  const register = async (email: string, password: string) => {
    setIsLoading(true)
    setError(null)
    setIsSuccess(false)

    try {
      await authService.register(email, password)
      setIsSuccess(true)
    } catch (err: any) {
      setError(err?.message || 'Registration failed. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return { register, isLoading, error, isSuccess }
}
