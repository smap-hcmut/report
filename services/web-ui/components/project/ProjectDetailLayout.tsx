import { ReactNode } from 'react'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import ProjectTabs from './ProjectTabs'

interface ProjectDetailLayoutProps {
  projectId: string
  children: ReactNode
}

export default function ProjectDetailLayout({
  projectId,
  children,
}: ProjectDetailLayoutProps) {
  return (
    <div className="flex flex-col h-screen relative bg-amber-50 dark:bg-gray-950 overflow-hidden">
      {/* Background Effects */}
      <div className="fixed inset-0 pointer-events-none">
        {/* Sun Mode - Warm Glows */}
        <div className="absolute top-0 right-1/4 w-[600px] h-[600px] bg-yellow-100/60 rounded-full blur-[128px] dark:hidden" />
        <div className="absolute bottom-1/4 left-1/3 w-[500px] h-[500px] bg-amber-100/50 rounded-full blur-[128px] dark:hidden" />

        {/* Dark Mode - Night Sky Stars */}
        <div
          className="hidden dark:block absolute inset-0"
          style={{
            backgroundImage: `
              radial-gradient(2px 2px at 20% 30%, white, transparent),
              radial-gradient(2px 2px at 60% 70%, white, transparent),
              radial-gradient(1px 1px at 50% 50%, white, transparent),
              radial-gradient(1px 1px at 80% 10%, white, transparent),
              radial-gradient(2px 2px at 90% 60%, white, transparent),
              radial-gradient(1px 1px at 33% 80%, white, transparent),
              radial-gradient(1px 1px at 15% 60%, white, transparent)
            `,
            backgroundSize: '200px 200px, 250px 250px, 150px 150px, 180px 180px, 220px 220px, 300px 300px, 280px 280px',
            backgroundPosition: '0 0, 40px 60px, 130px 270px, 70px 100px, 150px 50px, 250px 150px, 100px 200px',
            opacity: 0.4,
          }}
        />
        <div className="hidden dark:block absolute top-0 left-1/4 w-96 h-96 bg-white/5 rounded-full blur-[128px]" />
        <div className="hidden dark:block absolute bottom-1/3 right-1/4 w-[500px] h-[500px] bg-white/5 rounded-full blur-[128px]" />
      </div>

      <Navbar />

      <div className="relative z-10 flex flex-col flex-1 overflow-hidden">
        {/* Project Tabs Navigation */}
        <ProjectTabs projectId={projectId} />

        {/* Tab Content */}
        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>

      <Footer />
    </div>
  )
}
