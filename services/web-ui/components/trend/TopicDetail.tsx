import React, { useState } from 'react'
import { motion } from 'framer-motion'
import {
  ArrowLeft,
  TrendingUp,
  TrendingDown,
  Users,
  MessageSquare,
  BarChart3,
  Target,
  Calendar,
  ExternalLink,
  Heart,
  Share2,
  Eye,
  Download,
  Bookmark
} from 'lucide-react'
import { useTrend } from '@/contexts/TrendContext'

interface TopicDetailProps {
  topicId: string
  onBack: () => void
}

export default function TopicDetail({ topicId, onBack }: TopicDetailProps) {
  const { state } = useTrend()
  const [activeTab, setActiveTab] = useState<'overview' | 'posts' | 'analytics'>('overview')

  const topic = state.topics.find(t => t.id === topicId)

  if (!topic) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-center">
          <Target className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
          <h3 className="text-lg font-medium mb-2">Topic not found</h3>
          <p className="text-muted-foreground mb-4">The requested topic could not be found.</p>
          <button
            onClick={onBack}
            className="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
          >
            Go Back
          </button>
        </div>
      </div>
    )
  }

  const tabs = [
    { id: 'overview', label: 'Overview', icon: <BarChart3 className="h-4 w-4" /> },
    { id: 'posts', label: 'Sample Posts', icon: <MessageSquare className="h-4 w-4" /> },
    { id: 'analytics', label: 'Analytics', icon: <TrendingUp className="h-4 w-4" /> },
  ]

  const getSentimentColor = (sentiment: 'positive' | 'neutral' | 'negative') => {
    switch (sentiment) {
      case 'positive': return 'text-green-600 bg-green-100'
      case 'neutral': return 'text-gray-600 bg-gray-100'
      case 'negative': return 'text-red-600 bg-red-100'
    }
  }

  const getDominantSentiment = () => {
    const { positive, neutral, negative } = topic.sentiment
    if (positive >= neutral && positive >= negative) return 'positive'
    if (negative >= neutral && negative >= positive) return 'negative'
    return 'neutral'
  }

  const dominantSentiment = getDominantSentiment()

  return (
    <div className="h-full flex flex-col">
      {}
      <div className="p-6 border-b border-border bg-card/50">
        <div className="flex items-center gap-4 mb-4">
          <button
            onClick={onBack}
            className="flex items-center gap-2 px-3 py-2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Trends
          </button>
        </div>

        <div className="flex items-start justify-between">
          <div className="flex-1">
            <h1 className="text-2xl font-bold mb-2">{topic.name}</h1>
            <div className="flex items-center gap-4 text-sm text-muted-foreground">
              <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4" />
                <span>Updated {topic.createdAt.toLocaleDateString()}</span>
              </div>
              <div className="flex items-center gap-2">
                <Target className="h-4 w-4" />
                <span>{topic.platforms.join(', ')}</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className={`px-3 py-1 rounded-full text-sm font-medium ${getSentimentColor(dominantSentiment)}`}>
              {dominantSentiment}
            </div>
            <button className="p-2 hover:bg-muted rounded-lg transition-colors">
              <Bookmark className="h-4 w-4" />
            </button>
            <button className="p-2 hover:bg-muted rounded-lg transition-colors">
              <Download className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>

      {}
      <div className="border-b border-border">
        <div className="flex">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`flex items-center gap-2 px-6 py-4 text-sm font-medium transition-colors relative ${
                activeTab === tab.id
                  ? 'text-primary'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              {tab.icon}
              {tab.label}
              {activeTab === tab.id && (
                <motion.div
                  layoutId="activeTab"
                  className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary"
                  transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
                />
              )}
            </button>
          ))}
        </div>
      </div>

      {}
      <div className="flex-1 overflow-auto">
        {activeTab === 'overview' && (
          <div className="p-6 space-y-6">
            {}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="bg-card border border-border rounded-lg p-4">
                <div className="flex items-center gap-2 mb-2">
                  <Users className="h-5 w-5 text-blue-600" />
                  <span className="text-sm font-medium text-muted-foreground">Volume</span>
                </div>
                <p className="text-2xl font-bold">{topic.volume.toLocaleString()}</p>
                <div className="flex items-center gap-1 mt-1">
                  {topic.delta > 0 ? (
                    <TrendingUp className="h-3 w-3 text-green-600" />
                  ) : (
                    <TrendingDown className="h-3 w-3 text-red-600" />
                  )}
                  <span className={`text-xs ${
                    topic.delta > 0 ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {topic.delta > 0 ? '+' : ''}{topic.delta.toFixed(1)}%
                  </span>
                </div>
              </div>

              <div className="bg-card border border-border rounded-lg p-4">
                <div className="flex items-center gap-2 mb-2">
                  <BarChart3 className="h-5 w-5 text-purple-600" />
                  <span className="text-sm font-medium text-muted-foreground">Confidence</span>
                </div>
                <p className="text-2xl font-bold">{(topic.confidence * 100).toFixed(0)}%</p>
                <p className="text-xs text-muted-foreground mt-1">AI confidence score</p>
              </div>

              <div className="bg-card border border-border rounded-lg p-4">
                <div className="flex items-center gap-2 mb-2">
                  <Heart className="h-5 w-5 text-green-600" />
                  <span className="text-sm font-medium text-muted-foreground">Positive</span>
                </div>
                <p className="text-2xl font-bold">{topic.sentiment.positive}%</p>
                <p className="text-xs text-muted-foreground mt-1">Sentiment score</p>
              </div>

              <div className="bg-card border border-border rounded-lg p-4">
                <div className="flex items-center gap-2 mb-2">
                  <MessageSquare className="h-5 w-5 text-orange-600" />
                  <span className="text-sm font-medium text-muted-foreground">Samples</span>
                </div>
                <p className="text-2xl font-bold">{topic.samplePosts.length}</p>
                <p className="text-xs text-muted-foreground mt-1">Sample posts</p>
              </div>
            </div>

            {}
            <div className="bg-card border border-border rounded-lg p-6">
              <h3 className="text-lg font-semibold mb-4">Sentiment Analysis</h3>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-green-500 rounded-full" />
                    <span className="text-sm font-medium">Positive</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-32 h-2 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full bg-green-500"
                        style={{ width: `${topic.sentiment.positive}%` }}
                      />
                    </div>
                    <span className="text-sm font-medium w-12 text-right">{topic.sentiment.positive}%</span>
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-gray-500 rounded-full" />
                    <span className="text-sm font-medium">Neutral</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-32 h-2 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gray-500"
                        style={{ width: `${topic.sentiment.neutral}%` }}
                      />
                    </div>
                    <span className="text-sm font-medium w-12 text-right">{topic.sentiment.neutral}%</span>
                  </div>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-red-500 rounded-full" />
                    <span className="text-sm font-medium">Negative</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-32 h-2 bg-muted rounded-full overflow-hidden">
                      <div
                        className="h-full bg-red-500"
                        style={{ width: `${topic.sentiment.negative}%` }}
                      />
                    </div>
                    <span className="text-sm font-medium w-12 text-right">{topic.sentiment.negative}%</span>
                  </div>
                </div>
              </div>
            </div>

            {}
            <div className="bg-card border border-border rounded-lg p-6">
              <h3 className="text-lg font-semibold mb-4">Related Keywords</h3>
              <div className="flex flex-wrap gap-2">
                {topic.keywords.map((keyword, index) => (
                  <span
                    key={index}
                    className="px-3 py-1 bg-primary/10 text-primary text-sm rounded-full font-medium"
                  >
                    {keyword}
                  </span>
                ))}
              </div>
            </div>

            {}
            <div className="bg-card border border-border rounded-lg p-6">
              <h3 className="text-lg font-semibold mb-4">Active Platforms</h3>
              <div className="flex gap-2">
                {topic.platforms.map((platform, index) => (
                  <div
                    key={index}
                    className="flex items-center gap-2 px-3 py-2 bg-muted rounded-lg"
                  >
                    <div className="w-2 h-2 bg-primary rounded-full" />
                    <span className="text-sm font-medium capitalize">{platform}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'posts' && (
          <div className="p-6">
            <div className="mb-6">
              <h3 className="text-lg font-semibold mb-2">Sample Posts</h3>
              <p className="text-muted-foreground">
                Recent posts related to &quot;{topic.name}&quot; topic
              </p>
            </div>

            {topic.samplePosts.length === 0 ? (
              <div className="text-center py-12">
                <MessageSquare className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
                <h3 className="text-lg font-medium mb-2">No sample posts available</h3>
                <p className="text-muted-foreground">
                  Sample posts will appear here as they are collected
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {topic.samplePosts.map((post, index) => (
                  <div key={index} className="bg-card border border-border rounded-lg p-4">
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
                          <Users className="h-4 w-4 text-primary" />
                        </div>
                        <div>
                          <p className="font-medium">Sample Post {index + 1}</p>
                          <p className="text-sm text-muted-foreground">2 hours ago</p>
                        </div>
                      </div>
                      <button className="p-1 hover:bg-muted rounded transition-colors">
                        <ExternalLink className="h-4 w-4 text-muted-foreground" />
                      </button>
                    </div>

                    <p className="text-muted-foreground mb-3">
                      This is a sample post related to the topic. In a real implementation,
                      this would show actual content from social media platforms.
                    </p>

                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <Heart className="h-4 w-4" />
                        <span>1.2K</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <MessageSquare className="h-4 w-4" />
                        <span>89</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Share2 className="h-4 w-4" />
                        <span>45</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'analytics' && (
          <div className="p-6">
            <div className="mb-6">
              <h3 className="text-lg font-semibold mb-2">Analytics</h3>
              <p className="text-muted-foreground">
                Detailed analytics and insights for &quot;{topic.name}&quot;
              </p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {}
              <div className="bg-card border border-border rounded-lg p-6">
                <h4 className="font-semibold mb-4">Volume Trend</h4>
                <div className="h-48 flex items-center justify-center text-muted-foreground">
                  <div className="text-center">
                    <BarChart3 className="h-12 w-12 mx-auto mb-2 opacity-50" />
                    <p>Volume trend chart would appear here</p>
                  </div>
                </div>
              </div>

              {}
              <div className="bg-card border border-border rounded-lg p-6">
                <h4 className="font-semibold mb-4">Sentiment Trend</h4>
                <div className="h-48 flex items-center justify-center text-muted-foreground">
                  <div className="text-center">
                    <TrendingUp className="h-12 w-12 mx-auto mb-2 opacity-50" />
                    <p>Sentiment trend chart would appear here</p>
                  </div>
                </div>
              </div>

              {}
              <div className="bg-card border border-border rounded-lg p-6">
                <h4 className="font-semibold mb-4">Platform Distribution</h4>
                <div className="space-y-3">
                  {topic.platforms.map((platform, index) => (
                    <div key={index} className="flex items-center justify-between">
                      <span className="text-sm font-medium capitalize">{platform}</span>
                      <div className="flex items-center gap-2">
                        <div className="w-24 h-2 bg-muted rounded-full overflow-hidden">
                          <div
                            className="h-full bg-primary"
                            style={{ width: `${(100 / topic.platforms.length) + (index * 10)}%` }}
                          />
                        </div>
                        <span className="text-sm text-muted-foreground w-12 text-right">
                          {Math.round((100 / topic.platforms.length) + (index * 10))}%
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {}
              <div className="bg-card border border-border rounded-lg p-6">
                <h4 className="font-semibold mb-4">Top Keywords</h4>
                <div className="space-y-2">
                  {topic.keywords.slice(0, 5).map((keyword, index) => (
                    <div key={index} className="flex items-center justify-between">
                      <span className="text-sm font-medium">{keyword}</span>
                      <div className="flex items-center gap-2">
                        <div className="w-16 h-2 bg-muted rounded-full overflow-hidden">
                          <div
                            className="h-full bg-primary"
                            style={{ width: `${100 - (index * 15)}%` }}
                          />
                        </div>
                        <span className="text-sm text-muted-foreground w-8 text-right">
                          {100 - (index * 15)}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
