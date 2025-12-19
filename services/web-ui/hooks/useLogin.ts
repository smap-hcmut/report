import { useState } from 'react'
import { authService } from '@/lib/api/services/auth.service'

interface LoginPayload {
  device_name: string
  email: string
  ip_address: string
  password: string
  remember: boolean
  user_agent: string
}

interface LoginResult {
  needsOtp: boolean
  isVerified: boolean
  user?: any
  token?: string
}

interface UseLoginReturn {
  login: (payload: LoginPayload) => Promise<LoginResult>
  isLoading: boolean
  error: string | null
  isSuccess: boolean
}

export const useLogin = (): UseLoginReturn => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isSuccess, setIsSuccess] = useState(false)

  const login = async (payload: LoginPayload): Promise<LoginResult> => {
    setIsLoading(true)
    setError(null)
    setIsSuccess(false)

    try {
      const response = await authService.login(payload)

      // Check if user needs OTP verification (error_code 20009)
      if (response.error_code === 20009) {
        setIsLoading(false)
        return { needsOtp: true, isVerified: false }
      }

      // User is verified, login successful
      // Cookie is automatically set by browser via Set-Cookie header
      // Extract user from response
      const user = response.data?.user || response.user || response.data

      setIsSuccess(true)
      setIsLoading(false)
      return {
        needsOtp: false,
        isVerified: true,
        user: user
      }
    } catch (err: any) {
      // Check if error is the 20009 error (user not verified)
      if (err?.error_code === 20009) {
        setIsLoading(false)
        return { needsOtp: true, isVerified: false }
      }

      setError(err?.message || 'Login failed. Please try again.')
      setIsLoading(false)
      throw err
    }
  }

  return { login, isLoading, error, isSuccess }
}
