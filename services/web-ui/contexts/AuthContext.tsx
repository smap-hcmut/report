import React, { createContext, useState, useContext, useEffect, ReactNode } from 'react'
import { authService } from '@/lib/api/services/auth.service'

interface User {
  id: string
  email: string
  name?: string
  full_name?: string
  role?: string
  verified?: boolean
}

interface AuthContextType {
  user: User | null
  loading: boolean
  isAuthenticated: boolean
  checkAuth: () => Promise<void>
  logout: () => Promise<void>
  setUser: (user: User | null) => void
}

const AuthContext = createContext<AuthContextType | null>(null)

interface AuthProviderProps {
  children: ReactNode
}

export const AuthProvider = ({ children }: AuthProviderProps) => {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Check authentication status on mount
  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    try {
      const userData = await authService.me()
      setUser(userData)
    } catch (error: any) {
      // 401 is expected when not logged in, silently set user to null
      // Don't log error for 401 (unauthorized) responses
      if (error?.status !== 401) {
        console.error('Auth check error:', error)
      }
      setUser(null)
    } finally {
      setLoading(false)
    }
  }

  const logout = async () => {
    try {
      await authService.logout()
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      setUser(null)
    }
  }

  const value: AuthContextType = {
    user,
    loading,
    isAuthenticated: !!user,
    checkAuth,
    logout,
    setUser,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}
