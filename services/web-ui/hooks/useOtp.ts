import { useState } from 'react'
import { authService } from '@/lib/api/services/auth.service'

interface UseSendOtpReturn {
  sendOtp: (email: string, password: string) => Promise<void>
  isLoading: boolean
  error: string | null
  isSuccess: boolean
}

export const useSendOtp = (): UseSendOtpReturn => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isSuccess, setIsSuccess] = useState(false)

  const sendOtp = async (email: string, password: string) => {
    setIsLoading(true)
    setError(null)
    setIsSuccess(false)

    try {
      await authService.sendOtp(email, password)
      setIsSuccess(true)
    } catch (err: any) {
      setError(err?.message || 'Failed to send OTP. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return { sendOtp, isLoading, error, isSuccess }
}

interface UseVerifyOtpReturn {
  verifyOtp: (email: string, otp: string) => Promise<void>
  isLoading: boolean
  error: string | null
  isSuccess: boolean
  token: string | null
}

export const useVerifyOtp = (): UseVerifyOtpReturn => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isSuccess, setIsSuccess] = useState(false)
  const [token, setToken] = useState<string | null>(null)

  const verifyOtp = async (email: string, otp: string) => {
    setIsLoading(true)
    setError(null)
    setIsSuccess(false)

    try {
      const response = await authService.verifyOtp(email, otp)

      // Extract token and user from response
      const token = response.data?.token || response.token
      const user = response.data?.user || response.user || response.data

      // Store token and user data
      if (token) {
        localStorage.setItem('auth_token', token)
        setToken(token)
      }
      if (user) {
        localStorage.setItem('user', JSON.stringify(user))
      }

      // Dispatch custom event to notify Navbar of auth change
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new Event('authChange'))
      }

      setIsSuccess(true)
    } catch (err: any) {
      setError(err?.message || 'Invalid OTP code. Please try again.')
    } finally {
      setIsLoading(false)
    }
  }

  return { verifyOtp, isLoading, error, isSuccess, token }
}
