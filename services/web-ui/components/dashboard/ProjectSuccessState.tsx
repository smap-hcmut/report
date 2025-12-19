import React, { useEffect } from 'react'
import { motion } from 'framer-motion'
import {
  CheckCircle,
  ArrowRight,
  BarChart3,
  TrendingUp,
  Users,
  Target,
  Sparkles
} from 'lucide-react'
import { useDashboard } from '@/contexts/DashboardContext'

export default function ProjectSuccessState() {
  const { currentProject, setProject } = useDashboard()

  useEffect(() => {

    const timer = setTimeout(() => {
      if (currentProject) {
        setProject(currentProject.id)
      }
    }, 3000)

    return () => clearTimeout(timer)
  }, [currentProject, setProject])

  if (!currentProject) return null

  const features = [
    {
      icon: <TrendingUp className="h-6 w-6" />,
      title: "Trend Analysis",
      description: "Theo dõi xu hướng thảo luận theo thời gian thực"
    },
    {
      icon: <Users className="h-6 w-6" />,
      title: "Competitor Tracking",
      description: "So sánh với đối thủ cạnh tranh"
    },
    {
      icon: <BarChart3 className="h-6 w-6" />,
      title: "Share of Voice",
      description: "Đo lường tỷ lệ thị phần trong cuộc trò chuyện"
    }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-muted/20 flex items-center justify-center p-6">
      <div className="max-w-2xl w-full">
        {}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.6, type: "spring", stiffness: 200 }}
          className="text-center mb-8"
        >
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.2, type: "spring", stiffness: 300 }}
            className="inline-flex items-center justify-center w-24 h-24 bg-gradient-to-r from-green-500 to-emerald-600 rounded-full mb-6"
          >
            <CheckCircle className="h-12 w-12 text-white" />
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.6 }}
            className="text-3xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent mb-4"
          >
            Project đã sẵn sàng!
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6, duration: 0.6 }}
            className="text-lg text-muted-foreground"
          >
            <strong>{currentProject.name}</strong> đã được thiết lập thành công và sẵn sàng sử dụng
          </motion.p>
        </motion.div>

        {}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8, duration: 0.6 }}
          className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8"
        >
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 1 + index * 0.1, duration: 0.6 }}
              whileHover={{ scale: 1.02, y: -5 }}
              className="bg-card border border-border rounded-lg p-4 text-center hover:shadow-lg transition-all"
            >
              <div className="inline-flex items-center justify-center w-12 h-12 bg-primary/10 rounded-lg mb-3 text-primary">
                {feature.icon}
              </div>
              <h3 className="text-sm font-semibold mb-1">{feature.title}</h3>
              <p className="text-xs text-muted-foreground">{feature.description}</p>
            </motion.div>
          ))}
        </motion.div>

        {}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 1.2, duration: 0.6 }}
          className="bg-muted/50 rounded-lg p-6 mb-8"
        >
          <h3 className="font-semibold mb-4 flex items-center gap-2">
            <Target className="h-5 w-5" />
            Tóm tắt project
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <h4 className="text-sm font-medium text-muted-foreground mb-2">Thương hiệu của bạn</h4>
              <div className="space-y-1">
                {currentProject.brands.map((brand) => (
                  <div key={brand.id} className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-primary rounded-full" />
                    <span className="text-sm">{brand.name}</span>
                  </div>
                ))}
              </div>
            </div>

            <div>
              <h4 className="text-sm font-medium text-muted-foreground mb-2">Đối thủ cạnh tranh</h4>
              <div className="space-y-1">
                {currentProject.competitors.map((competitor) => (
                  <div key={competitor.id} className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-orange-500 rounded-full" />
                    <span className="text-sm">{competitor.name}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>

        {}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.4, duration: 0.6 }}
          className="text-center"
        >
          <div className="inline-flex items-center gap-2 text-sm text-muted-foreground bg-muted/50 rounded-full px-4 py-2">
            <Sparkles className="h-4 w-4" />
            <span>Đang chuyển hướng đến dashboard...</span>
          </div>
        </motion.div>
      </div>
    </div>
  )
}
