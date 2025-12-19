import React from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { DryRunContent, Platform } from '@/lib/types/dryrun'
import PreviewPostCard from './PreviewPostCard'
import { useTranslation } from 'next-i18next'

interface PreviewPostListProps {
  posts: DryRunContent[]
  platform: Platform
}

export default function PreviewPostList({ posts, platform }: PreviewPostListProps) {
  const { t } = useTranslation('common')

  if (posts.length === 0) {
    return (
      <div className="text-center py-12 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-xl">
        <p className="text-gray-600 dark:text-gray-400">{t('preview.noPosts')}</p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-black text-gray-900 dark:text-white">
        {t('preview.samplePosts')} ({posts.length})
      </h3>

      <AnimatePresence mode="popLayout">
        {posts.map((post, index) => (
          <motion.div
            key={post.meta.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ delay: index * 0.05 }}
          >
            <PreviewPostCard post={post} platform={platform} />
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}
