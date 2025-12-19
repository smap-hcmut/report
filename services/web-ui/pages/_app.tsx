import '../styles/globals.css'
import 'reactflow/dist/style.css'
import '../styles/reactflow-custom.css'
import type { AppProps } from 'next/app'
import { appWithTranslation } from 'next-i18next'
import { ThemeProvider } from '@/components/ThemeProvider'
import { DashboardProvider } from '@/contexts/DashboardContext'
import { AuthProvider } from '@/contexts/AuthContext'
import nextI18NextConfig from '../next-i18next.config.js'

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      disableTransitionOnChange
    >
      <AuthProvider>
        <DashboardProvider>
          <Component {...pageProps} />
        </DashboardProvider>
      </AuthProvider>
    </ThemeProvider>
  )
}

export default appWithTranslation(MyApp, nextI18NextConfig)
