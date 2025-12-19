import React, { useState } from 'react'
import { motion } from 'framer-motion'
import {
  Facebook,
  Instagram,
  Twitter,
  Youtube,
  Linkedin,
  MessageSquare,
  Check,
  AlertCircle,
  ExternalLink
} from 'lucide-react'
import { useReport } from '@/contexts/ReportContext'

export default function DataSourceSelector() {
  const { state, updateConfig } = useReport()
  const [showConnectionModal, setShowConnectionModal] = useState(false)

  const dataSources = [
    {
      id: 'facebook',
      name: 'Facebook',
      icon: <Facebook className="h-5 w-5" />,
      color: 'bg-blue-600',
      description: 'Pages, posts, and engagement data',
      connected: true,
      lastSync: '2 hours ago',
      dataTypes: ['Posts', 'Comments', 'Reactions', 'Shares']
    },
    {
      id: 'instagram',
      name: 'Instagram',
      icon: <Instagram className="h-5 w-5" />,
      color: 'bg-pink-600',
      description: 'Posts, stories, and IGTV content',
      connected: true,
      lastSync: '1 hour ago',
      dataTypes: ['Posts', 'Stories', 'Reels', 'IGTV']
    },
    {
      id: 'tiktok',
      name: 'TikTok',
      icon: <MessageSquare className="h-5 w-5" />,
      color: 'bg-black',
      description: 'Videos, hashtags, and trends',
      connected: false,
      lastSync: null,
      dataTypes: ['Videos', 'Hashtags', 'Trends', 'Comments']
    },
    {
      id: 'twitter',
      name: 'Twitter',
      icon: <Twitter className="h-5 w-5" />,
      color: 'bg-blue-400',
      description: 'Tweets, mentions, and engagement',
      connected: true,
      lastSync: '30 minutes ago',
      dataTypes: ['Tweets', 'Retweets', 'Replies', 'Likes']
    },
    {
      id: 'youtube',
      name: 'YouTube',
      icon: <Youtube className="h-5 w-5" />,
      color: 'bg-red-600',
      description: 'Videos, comments, and analytics',
      connected: false,
      lastSync: null,
      dataTypes: ['Videos', 'Comments', 'Views', 'Subscribers']
    },
    {
      id: 'linkedin',
      name: 'LinkedIn',
      icon: <Linkedin className="h-5 w-5" />,
      color: 'bg-blue-700',
      description: 'Company pages and posts',
      connected: true,
      lastSync: '4 hours ago',
      dataTypes: ['Posts', 'Company Updates', 'Engagement']
    }
  ]

  const handleDataSourceToggle = (sourceId: string) => {
    const currentSources = state.config?.dataSources || []
    const newSources = currentSources.includes(sourceId)
      ? currentSources.filter(id => id !== sourceId)
      : [...currentSources, sourceId]

    updateConfig({ dataSources: newSources })
  }

  const handleConnectSource = (sourceId: string) => {

    console.log('Connecting to:', sourceId)
    setShowConnectionModal(true)
  }

  const getSelectedCount = () => {
    return state.config?.dataSources.length || 0
  }

  const getConnectedCount = () => {
    return dataSources.filter(source => source.connected).length
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Select Data Sources</h2>
        <p className="text-muted-foreground">
          Choose which social media platforms to include in your report
        </p>
      </div>

      {}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div className="p-4 bg-muted/50 rounded-lg border border-border">
          <div className="text-2xl font-bold text-primary">{getSelectedCount()}</div>
          <div className="text-sm text-muted-foreground">Sources Selected</div>
        </div>
        <div className="p-4 bg-muted/50 rounded-lg border border-border">
          <div className="text-2xl font-bold text-green-600">{getConnectedCount()}</div>
          <div className="text-sm text-muted-foreground">Connected Sources</div>
        </div>
        <div className="p-4 bg-muted/50 rounded-lg border border-border">
          <div className="text-2xl font-bold text-orange-600">{dataSources.length - getConnectedCount()}</div>
          <div className="text-sm text-muted-foreground">Available to Connect</div>
        </div>
      </div>

      {}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {dataSources.map((source, index) => (
          <motion.div
            key={source.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: index * 0.1 }}
            className={`relative p-6 border-2 rounded-lg transition-all ${
              state.config?.dataSources.includes(source.id)
                ? 'border-primary bg-primary/5'
                : 'border-border hover:border-primary/50'
            } ${!source.connected ? 'opacity-60' : 'cursor-pointer'}`}
            onClick={() => source.connected && handleDataSourceToggle(source.id)}
          >
            {}
            {state.config?.dataSources.includes(source.id) && (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                className="absolute top-4 right-4 w-6 h-6 bg-primary text-primary-foreground rounded-full flex items-center justify-center"
              >
                <Check className="h-4 w-4" />
              </motion.div>
            )}

            {}
            <div className="absolute top-4 left-4">
              {source.connected ? (
                <div className="w-3 h-3 bg-green-500 rounded-full" />
              ) : (
                <div className="w-3 h-3 bg-gray-400 rounded-full" />
              )}
            </div>

            {}
            <div className={`w-12 h-12 ${source.color} rounded-lg flex items-center justify-center text-white mb-4`}>
              {source.icon}
            </div>

            {}
            <div className="mb-4">
              <h3 className="text-lg font-semibold mb-1">{source.name}</h3>
              <p className="text-sm text-muted-foreground">{source.description}</p>
            </div>

            {}
            <div className="mb-4">
              {source.connected ? (
                <div className="text-sm text-green-600">
                  <div className="font-medium">Connected</div>
                  <div>Last sync: {source.lastSync}</div>
                </div>
              ) : (
                <div className="text-sm text-muted-foreground">
                  <div className="font-medium">Not Connected</div>
                  <div>Click to connect</div>
                </div>
              )}
            </div>

            {}
            <div className="mb-4">
              <div className="text-xs font-medium text-muted-foreground mb-2">Available Data:</div>
              <div className="flex flex-wrap gap-1">
                {source.dataTypes.map((type) => (
                  <span
                    key={type}
                    className="px-2 py-1 bg-muted text-muted-foreground text-xs rounded-md"
                  >
                    {type}
                  </span>
                ))}
              </div>
            </div>

            {}
            {!source.connected && (
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  handleConnectSource(source.id)
                }}
                className="w-full mt-4 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors text-sm"
              >
                Connect {source.name}
              </button>
            )}

            {}
            {source.connected && (
              <div className="absolute inset-0 rounded-lg bg-gradient-to-r from-primary/5 to-violet-500/5 opacity-0 hover:opacity-100 transition-opacity pointer-events-none" />
            )}
          </motion.div>
        ))}
      </div>

      {}
      {getSelectedCount() > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-8 p-6 bg-muted/50 rounded-lg border border-border"
        >
          <h3 className="text-lg font-semibold mb-4">Selected Data Sources</h3>
          <div className="flex flex-wrap gap-2">
            {state.config?.dataSources.map((sourceId) => {
              const source = dataSources.find(s => s.id === sourceId)
              return source ? (
                <div
                  key={sourceId}
                  className="flex items-center gap-2 px-3 py-2 bg-primary/10 text-primary rounded-lg"
                >
                  <div className={`w-4 h-4 ${source.color} rounded flex items-center justify-center text-white text-xs`}>
                    {source.icon}
                  </div>
                  <span className="text-sm font-medium">{source.name}</span>
                </div>
              ) : null
            })}
          </div>
        </motion.div>
      )}

      {}
      {getSelectedCount() === 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-8 p-4 bg-yellow-50 border border-yellow-200 rounded-lg"
        >
          <div className="flex items-center gap-2 text-yellow-800">
            <AlertCircle className="h-4 w-4" />
            <span className="font-medium">No Data Sources Selected</span>
          </div>
          <p className="text-sm text-yellow-700 mt-1">
            Please select at least one data source to generate your report.
          </p>
        </motion.div>
      )}
    </div>
  )
}
