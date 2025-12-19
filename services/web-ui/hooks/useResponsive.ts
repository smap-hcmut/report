import { useState, useEffect } from 'react'

export interface BreakpointConfig {
  sm: number
  md: number
  lg: number
  xl: number
  '2xl': number
}

export interface ResponsiveState {
  isMobile: boolean
  isTablet: boolean
  isDesktop: boolean
  isLargeDesktop: boolean
  screenWidth: number
  screenHeight: number
  breakpoint: keyof BreakpointConfig | 'xs'
}

const defaultBreakpoints: BreakpointConfig = {
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  '2xl': 1536
}

export function useResponsive(breakpoints: BreakpointConfig = defaultBreakpoints) {
  const [state, setState] = useState<ResponsiveState>({
    isMobile: false,
    isTablet: false,
    isDesktop: false,
    isLargeDesktop: false,
    screenWidth: 0,
    screenHeight: 0,
    breakpoint: 'xs'
  })

  useEffect(() => {
    const updateState = () => {
      const width = window.innerWidth
      const height = window.innerHeight

      let breakpoint: keyof BreakpointConfig | 'xs' = 'xs'
      if (width >= breakpoints['2xl']) breakpoint = '2xl'
      else if (width >= breakpoints.xl) breakpoint = 'xl'
      else if (width >= breakpoints.lg) breakpoint = 'lg'
      else if (width >= breakpoints.md) breakpoint = 'md'
      else if (width >= breakpoints.sm) breakpoint = 'sm'

      setState({
        isMobile: width < breakpoints.md,
        isTablet: width >= breakpoints.md && width < breakpoints.lg,
        isDesktop: width >= breakpoints.lg && width < breakpoints.xl,
        isLargeDesktop: width >= breakpoints.xl,
        screenWidth: width,
        screenHeight: height,
        breakpoint
      })
    }

    updateState()

    window.addEventListener('resize', updateState)

    return () => window.removeEventListener('resize', updateState)
  }, [breakpoints])

  return state
}

export function useBreakpoint(breakpoint: keyof BreakpointConfig) {
  const { screenWidth } = useResponsive()
  const breakpoints = defaultBreakpoints

  return screenWidth >= breakpoints[breakpoint]
}

export function useIsMobile() {
  const { isMobile } = useResponsive()
  return isMobile
}

export function useIsTablet() {
  const { isTablet } = useResponsive()
  return isTablet
}

export function useIsDesktop() {
  const { isDesktop } = useResponsive()
  return isDesktop
}
