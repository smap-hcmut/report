import apiClient from '../config'

interface RegisterPayload {
  email: string
  password: string
}

interface RegisterResponse {
  message?: string
  data?: any
}

interface LoginPayload {
  device_name: string
  email: string
  ip_address: string
  password: string
  remember: boolean
  user_agent: string
}

interface LoginResponse {
  message?: string
  data?: any
  token?: string
  user?: any
  error_code?: number
}

interface SendOtpPayload {
  email: string
  password: string
}

interface SendOtpResponse {
  message?: string
  data?: any
}

interface VerifyOtpPayload {
  email: string
  otp: string
}

interface VerifyOtpResponse {
  message?: string
  data?: any
  token?: string
  user?: any
}

interface User {
  id: string
  email: string
  name?: string
  full_name?: string
  role?: string
  verified?: boolean
}

interface MeResponse {
  code: number
  data: User
}

export const authService = {
  register: async (email: string, password: string): Promise<RegisterResponse> => {
    const response = await apiClient.post<RegisterResponse>('/identity/authentication/register', {
      email,
      password,
    })
    return response.data
  },

  login: async (payload: LoginPayload): Promise<LoginResponse> => {
    const response = await apiClient.post<LoginResponse>('/identity/authentication/login', payload)
    return response.data
  },

  sendOtp: async (email: string, password: string): Promise<SendOtpResponse> => {
    const response = await apiClient.post<SendOtpResponse>('/identity/authentication/send-otp', {
      email,
      password,
    })
    return response.data
  },

  verifyOtp: async (email: string, otp: string): Promise<VerifyOtpResponse> => {
    const response = await apiClient.post<VerifyOtpResponse>('/identity/authentication/verify-otp', {
      email,
      otp,
    })
    return response.data
  },

  // NEW: Logout endpoint - expires HttpOnly cookie
  logout: async (): Promise<void> => {
    await apiClient.post('/identity/authentication/logout')
  },

  // NEW: Get current user - checks auth status via cookie
  me: async (): Promise<User> => {
    const response = await apiClient.get<MeResponse>('/identity/authentication/me')
    return response.data.data
  },
}
