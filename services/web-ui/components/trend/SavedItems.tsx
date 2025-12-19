import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  BookmarkCheck,
  X,
  TrendingUp,
  Hash,
  FileText,
  Trash2,
  Share2,
  ExternalLink
} from 'lucide-react'
import { useTrend } from '@/contexts/TrendContext'

export default function SavedItems() {
  const { state, toggleSavedItem } = useTrend()
  const [isOpen, setIsOpen] = useState(false)

  const savedTopics = state.topics.filter(topic => state.savedItems.topics.includes(topic.id))
  const savedHashtags = state.hashtags.filter(hashtag => state.savedItems.hashtags.includes(hashtag.id))
  const savedPosts = state.samplePosts.filter(post => state.savedItems.posts.includes(post.id))

  const totalSaved = savedTopics.length + savedHashtags.length + savedPosts.length

  if (totalSaved === 0) {
    return null
  }

  return (
    <>
      {}
      <motion.button
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        onClick={() => setIsOpen(true)}
        className="fixed bottom-6 right-6 z-50 p-4 bg-primary text-primary-foreground rounded-full shadow-lg hover:shadow-xl transition-all"
        title={`${totalSaved} saved items`}
      >
        <BookmarkCheck className="h-6 w-6" />
        {totalSaved > 0 && (
          <motion.span
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full h-6 w-6 flex items-center justify-center font-bold"
          >
            {totalSaved}
          </motion.span>
        )}
      </motion.button>

      {}
      <AnimatePresence>
        {isOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/50 z-50"
              onClick={() => setIsOpen(false)}
            />

            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-full max-w-4xl max-h-[80vh] bg-card border border-border rounded-lg shadow-xl z-50 overflow-hidden"
            >
              {}
              <div className="flex items-center justify-between p-6 border-b border-border">
                <div className="flex items-center gap-3">
                  <BookmarkCheck className="h-6 w-6 text-primary" />
                  <h2 className="text-xl font-semibold">Saved Items</h2>
                  <span className="px-2 py-1 bg-primary/10 text-primary text-sm rounded-full">
                    {totalSaved} items
                  </span>
                </div>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-2 hover:bg-muted rounded-lg transition-colors"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              {}
              <div className="p-6 overflow-y-auto max-h-[60vh]">
                <div className="space-y-6">
                  {}
                  {savedTopics.length > 0 && (
                    <div>
                      <div className="flex items-center gap-2 mb-4">
                        <TrendingUp className="h-5 w-5 text-blue-600" />
                        <h3 className="text-lg font-semibold">Saved Topics ({savedTopics.length})</h3>
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {savedTopics.map((topic) => (
                          <motion.div
                            key={topic.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            className="bg-muted/50 border border-border rounded-lg p-4"
                          >
                            <div className="flex items-start justify-between mb-2">
                              <h4 className="font-medium">{topic.name}</h4>
                              <button
                                onClick={() => toggleSavedItem('topics', topic.id)}
                                className="p-1 hover:bg-muted rounded transition-colors text-red-500"
                                title="Remove from saved"
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            </div>
                            <div className="flex items-center gap-4 text-sm text-muted-foreground">
                              <span>{topic.volume.toLocaleString()} volume</span>
                              <span>{(topic.confidence * 100).toFixed(0)}% confidence</span>
                            </div>
                          </motion.div>
                        ))}
                      </div>
                    </div>
                  )}

                  {}
                  {savedHashtags.length > 0 && (
                    <div>
                      <div className="flex items-center gap-2 mb-4">
                        <Hash className="h-5 w-5 text-purple-600" />
                        <h3 className="text-lg font-semibold">Saved Hashtags ({savedHashtags.length})</h3>
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {savedHashtags.map((hashtag) => (
                          <motion.div
                            key={hashtag.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            className="bg-muted/50 border border-border rounded-lg p-4"
                          >
                            <div className="flex items-start justify-between mb-2">
                              <h4 className="font-medium">{hashtag.hashtag}</h4>
                              <button
                                onClick={() => toggleSavedItem('hashtags', hashtag.id)}
                                className="p-1 hover:bg-muted rounded transition-colors text-red-500"
                                title="Remove from saved"
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            </div>
                            <div className="flex items-center gap-4 text-sm text-muted-foreground">
                              <span>{hashtag.volume.toLocaleString()} volume</span>
                              <span>{hashtag.engagementRate.toFixed(1)}% ER</span>
                            </div>
                          </motion.div>
                        ))}
                      </div>
                    </div>
                  )}

                  {}
                  {savedPosts.length > 0 && (
                    <div>
                      <div className="flex items-center gap-2 mb-4">
                        <FileText className="h-5 w-5 text-green-600" />
                        <h3 className="text-lg font-semibold">Saved Posts ({savedPosts.length})</h3>
                      </div>
                      <div className="space-y-4">
                        {savedPosts.map((post) => (
                          <motion.div
                            key={post.id}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            className="bg-muted/50 border border-border rounded-lg p-4"
                          >
                            <div className="flex items-start justify-between mb-2">
                              <div className="flex-1">
                                <h4 className="font-medium mb-1">{post.title}</h4>
                                <p className="text-sm text-muted-foreground line-clamp-2">{post.content}</p>
                              </div>
                              <button
                                onClick={() => toggleSavedItem('posts', post.id)}
                                className="p-1 hover:bg-muted rounded transition-colors text-red-500 ml-4"
                                title="Remove from saved"
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            </div>
                            <div className="flex items-center justify-between text-sm text-muted-foreground">
                              <div className="flex items-center gap-4">
                                <span>@{post.author}</span>
                                <span>{post.platform}</span>
                                <span>{post.metrics.likes.toLocaleString()} likes</span>
                              </div>
                              <a
                                href={post.canonicalUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center gap-1 hover:text-primary transition-colors"
                              >
                                <ExternalLink className="h-3 w-3" />
                                View
                              </a>
                            </div>
                          </motion.div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {}
              <div className="flex items-center justify-between p-6 border-t border-border bg-muted/30">
                <div className="text-sm text-muted-foreground">
                  {totalSaved} items saved • Click the bookmark icon to save more
                </div>
                <div className="flex items-center gap-2">
                  <button className="px-4 py-2 text-sm bg-muted hover:bg-muted/80 rounded-lg transition-colors">
                    Export All
                  </button>
                  <button className="px-4 py-2 text-sm bg-primary text-primary-foreground hover:bg-primary/90 rounded-lg transition-colors">
                    Share Collection
                  </button>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </>
  )
}
