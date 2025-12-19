import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react'

export interface TrendTopic {
  id: string
  name: string
  volume: number
  delta: number
  confidence: number
  sentiment: {
    positive: number
    neutral: number
    negative: number
  }
  platforms: string[]
  keywords: string[]
  samplePosts: TrendPost[]
  createdAt: Date
}

export interface TrendPost {
  id: string
  title: string
  content: string
  canonicalUrl: string
  platform: string
  author: string
  publishedAt: Date
  metrics: {
    likes: number
    shares: number
    comments: number
    views: number
  }
  sentiment: {
    label: 'positive' | 'neutral' | 'negative'
    score: number
  }
}

export interface TrendHashtag {
  id: string
  hashtag: string
  volume: number
  engagementRate: number
  samplePosts: string[]
  platforms: string[]
}

export interface TrendFilters {
  timeRange: string
  platforms: string[]
  industries: string[]
  keywords: string[]
  minVolume: number
  minConfidence: number
  sentiment: string[]
  customDateRange?: {
    start: Date
    end: Date
  }
}

export interface TrendState {
  topics: TrendTopic[]
  hashtags: TrendHashtag[]
  samplePosts: TrendPost[]
  filters: TrendFilters
  isLoading: boolean
  error: string | null
  lastUpdate: Date | null
  selectedTopic: string | null
  searchQuery: string
  viewMode: 'topics' | 'hashtags' | 'posts'
  sortBy: 'volume' | 'delta' | 'confidence' | 'sentiment'
  sortOrder: 'asc' | 'desc'
  savedItems: {
    topics: string[]
    hashtags: string[]
    posts: string[]
  }
}

export type TrendAction =
  | { type: 'SET_TOPICS'; payload: TrendTopic[] }
  | { type: 'SET_HASHTAGS'; payload: TrendHashtag[] }
  | { type: 'SET_SAMPLE_POSTS'; payload: TrendPost[] }
  | { type: 'SET_FILTERS'; payload: Partial<TrendFilters> }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SET_LAST_UPDATE'; payload: Date }
  | { type: 'SET_SELECTED_TOPIC'; payload: string | null }
  | { type: 'SET_SEARCH_QUERY'; payload: string }
  | { type: 'SET_VIEW_MODE'; payload: 'topics' | 'hashtags' | 'posts' }
  | { type: 'SET_SORT'; payload: { by: 'volume' | 'delta' | 'confidence' | 'sentiment'; order: 'asc' | 'desc' } }
  | { type: 'RESET_FILTERS' }
  | { type: 'TOGGLE_SAVED_ITEM'; payload: { type: 'topics' | 'hashtags' | 'posts'; id: string } }

const initialState: TrendState = {
  topics: [],
  hashtags: [],
  samplePosts: [],
  filters: {
    timeRange: '7d',
    platforms: [],
    industries: [],
    keywords: [],
    minVolume: 100,
    minConfidence: 0.7,
    sentiment: []
  },
  isLoading: false,
  error: null,
  lastUpdate: null,
  selectedTopic: null,
  searchQuery: '',
  viewMode: 'topics',
  sortBy: 'volume',
  sortOrder: 'desc',
  savedItems: {
    topics: [],
    hashtags: [],
    posts: []
  }
}

function trendReducer(state: TrendState, action: TrendAction): TrendState {
  switch (action.type) {
    case 'SET_TOPICS':
      return { ...state, topics: action.payload }

    case 'SET_HASHTAGS':
      return { ...state, hashtags: action.payload }

    case 'SET_SAMPLE_POSTS':
      return { ...state, samplePosts: action.payload }

    case 'SET_FILTERS':
      return {
        ...state,
        filters: { ...state.filters, ...action.payload }
      }

    case 'SET_LOADING':
      return { ...state, isLoading: action.payload }

    case 'SET_ERROR':
      return { ...state, error: action.payload }

    case 'SET_LAST_UPDATE':
      return { ...state, lastUpdate: action.payload }

    case 'SET_SELECTED_TOPIC':
      return { ...state, selectedTopic: action.payload }

    case 'SET_SEARCH_QUERY':
      return { ...state, searchQuery: action.payload }

    case 'SET_VIEW_MODE':
      return { ...state, viewMode: action.payload }

    case 'SET_SORT':
      return {
        ...state,
        sortBy: action.payload.by,
        sortOrder: action.payload.order
      }

    case 'RESET_FILTERS':
      return {
        ...state,
        filters: initialState.filters
      }

    case 'TOGGLE_SAVED_ITEM':
      const { type, id } = action.payload
      const currentSaved = state.savedItems[type]
      const isSaved = currentSaved.includes(id)

      return {
        ...state,
        savedItems: {
          ...state.savedItems,
          [type]: isSaved
            ? currentSaved.filter(itemId => itemId !== id)
            : [...currentSaved, id]
        }
      }

    default:
      return state
  }
}

interface TrendContextType {
  state: TrendState
  dispatch: React.Dispatch<TrendAction>

  filteredTopics: TrendTopic[]
  filteredHashtags: TrendHashtag[]
  filteredPosts: TrendPost[]

  setFilters: (filters: Partial<TrendFilters>) => void
  setSelectedTopic: (topicId: string | null) => void
  setSearchQuery: (query: string) => void
  setViewMode: (mode: 'topics' | 'hashtags' | 'posts') => void
  setSort: (by: 'volume' | 'delta' | 'confidence' | 'sentiment', order: 'asc' | 'desc') => void
  resetFilters: () => void
  refreshData: () => void
  toggleSavedItem: (type: 'topics' | 'hashtags' | 'posts', id: string) => void
  isItemSaved: (type: 'topics' | 'hashtags' | 'posts', id: string) => boolean
}

const TrendContext = createContext<TrendContextType | undefined>(undefined)

interface TrendProviderProps {
  children: ReactNode
}

export function TrendProvider({ children }: TrendProviderProps) {
  const [state, dispatch] = useReducer(trendReducer, initialState)

  const generateMockData = () => {
    const mockTopics: TrendTopic[] = [
      {
        id: '1',
        name: 'Coffee Culture',
        volume: 15420,
        delta: 12.5,
        confidence: 0.89,
        sentiment: { positive: 65, neutral: 25, negative: 10 },
        platforms: ['facebook', 'tiktok', 'instagram'],
        keywords: ['coffee', 'cafe', 'barista', 'espresso'],
        samplePosts: [],
        createdAt: new Date()
      },
      {
        id: '2',
        name: 'Sustainable Fashion',
        volume: 12890,
        delta: -3.2,
        confidence: 0.76,
        sentiment: { positive: 78, neutral: 18, negative: 4 },
        platforms: ['instagram', 'tiktok'],
        keywords: ['sustainable', 'eco-friendly', 'fashion', 'green'],
        samplePosts: [],
        createdAt: new Date()
      },
      {
        id: '3',
        name: 'Remote Work',
        volume: 9870,
        delta: 8.7,
        confidence: 0.82,
        sentiment: { positive: 45, neutral: 40, negative: 15 },
        platforms: ['linkedin', 'twitter', 'facebook'],
        keywords: ['remote', 'work from home', 'flexible', 'digital nomad'],
        samplePosts: [],
        createdAt: new Date()
      }
    ]

    const mockHashtags: TrendHashtag[] = [
      {
        id: '1',
        hashtag: '#coffee',
        volume: 45200,
        engagementRate: 4.8,
        samplePosts: ['post1', 'post2', 'post3'],
        platforms: ['instagram', 'tiktok']
      },
      {
        id: '2',
        hashtag: '#sustainablefashion',
        volume: 23400,
        engagementRate: 6.2,
        samplePosts: ['post4', 'post5'],
        platforms: ['instagram']
      },
      {
        id: '3',
        hashtag: '#remotework',
        volume: 18900,
        engagementRate: 3.5,
        samplePosts: ['post6', 'post7', 'post8'],
        platforms: ['linkedin', 'twitter']
      },
      {
        id: '4',
        hashtag: '#digitalnomad',
        volume: 15600,
        engagementRate: 5.8,
        samplePosts: ['post9', 'post10'],
        platforms: ['instagram', 'tiktok', 'youtube']
      },
      {
        id: '5',
        hashtag: '#workfromhome',
        volume: 32100,
        engagementRate: 2.9,
        samplePosts: ['post11', 'post12', 'post13', 'post14'],
        platforms: ['facebook', 'linkedin']
      },
      {
        id: '6',
        hashtag: '#coffeelover',
        volume: 12800,
        engagementRate: 7.2,
        samplePosts: ['post15', 'post16'],
        platforms: ['instagram']
      }
    ]

    const mockPosts: TrendPost[] = [
      {
        id: '1',
        title: 'Amazing coffee art at local cafe',
        content: 'Just discovered this incredible coffee shop with the most beautiful latte art. The barista is truly an artist! ☕️✨ #coffee #latteart #localbusiness',
        canonicalUrl: 'https://instagram.com/p/example1',
        platform: 'instagram',
        author: '@coffeelover',
        publishedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
        metrics: { likes: 1250, shares: 45, comments: 89, views: 5600 },
        sentiment: { label: 'positive', score: 0.8 }
      },
      {
        id: '2',
        title: 'Sustainable fashion is the future',
        content: 'Love seeing more brands embracing eco-friendly practices. This dress is made from recycled materials and looks amazing! 🌱 #sustainablefashion #ecofriendly',
        canonicalUrl: 'https://instagram.com/p/example2',
        platform: 'instagram',
        author: '@ecofashionista',
        publishedAt: new Date(Date.now() - 4 * 60 * 60 * 1000),
        metrics: { likes: 890, shares: 120, comments: 45, views: 3200 },
        sentiment: { label: 'positive', score: 0.9 }
      },
      {
        id: '3',
        title: 'Remote work productivity tips',
        content: 'After 2 years of remote work, here are my top productivity tips: 1) Dedicated workspace 2) Time blocking 3) Regular breaks 4) Clear boundaries. What works for you? #remotework #productivity',
        canonicalUrl: 'https://linkedin.com/posts/example3',
        platform: 'linkedin',
        author: '@remoteworker',
        publishedAt: new Date(Date.now() - 6 * 60 * 60 * 1000),
        metrics: { likes: 2100, shares: 340, comments: 156, views: 8900 },
        sentiment: { label: 'positive', score: 0.7 }
      },
      {
        id: '4',
        title: 'Digital nomad life in Bali',
        content: 'Working from paradise today! The internet is surprisingly good here. Coffee shop hopping while getting work done. This is the life! 🏝️ #digitalnomad #bali #workfromanywhere',
        canonicalUrl: 'https://instagram.com/p/example4',
        platform: 'instagram',
        author: '@nomadlife',
        publishedAt: new Date(Date.now() - 8 * 60 * 60 * 1000),
        metrics: { likes: 3200, shares: 89, comments: 234, views: 12000 },
        sentiment: { label: 'positive', score: 0.85 }
      },
      {
        id: '5',
        title: 'Work from home setup tour',
        content: 'Finally organized my home office! Here\'s my complete WFH setup. The standing desk has been a game changer for my productivity. #workfromhome #homeoffice #productivity',
        canonicalUrl: 'https://tiktok.com/@example5',
        platform: 'tiktok',
        author: '@wfhsetup',
        publishedAt: new Date(Date.now() - 12 * 60 * 60 * 1000),
        metrics: { likes: 4500, shares: 567, comments: 89, views: 25000 },
        sentiment: { label: 'positive', score: 0.75 }
      },
      {
        id: '6',
        title: 'Coffee shop recommendations in NYC',
        content: 'Best coffee shops in NYC for remote work: 1) Blue Bottle 2) Stumptown 3) La Colombe 4) Intelligentsia. All have great wifi and atmosphere! #coffee #nyc #remotework',
        canonicalUrl: 'https://twitter.com/example6',
        platform: 'twitter',
        author: '@nyccoffee',
        publishedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        metrics: { likes: 780, shares: 123, comments: 67, views: 4200 },
        sentiment: { label: 'positive', score: 0.8 }
      }
    ]

    dispatch({ type: 'SET_TOPICS', payload: mockTopics })
    dispatch({ type: 'SET_HASHTAGS', payload: mockHashtags })
    dispatch({ type: 'SET_SAMPLE_POSTS', payload: mockPosts })
    dispatch({ type: 'SET_LAST_UPDATE', payload: new Date() })
  }

  useEffect(() => {
    dispatch({ type: 'SET_LOADING', payload: true })

    setTimeout(() => {
      generateMockData()
      dispatch({ type: 'SET_LOADING', payload: false })
    }, 1000)
  }, [])

  const filteredTopics = React.useMemo(() => {
    let filtered = state.topics

    if (state.searchQuery) {
      filtered = filtered.filter(topic =>
        topic.name.toLowerCase().includes(state.searchQuery.toLowerCase()) ||
        topic.keywords.some(keyword =>
          keyword.toLowerCase().includes(state.searchQuery.toLowerCase())
        )
      )
    }

    if (state.filters.platforms.length > 0) {
      filtered = filtered.filter(topic =>
        state.filters.platforms.some(platform =>
          topic.platforms.includes(platform)
        )
      )
    }

    filtered = filtered.filter(topic => topic.volume >= state.filters.minVolume)

    filtered = filtered.filter(topic => topic.confidence >= state.filters.minConfidence)

    filtered.sort((a, b) => {
      let aValue: number, bValue: number

      switch (state.sortBy) {
        case 'volume':
          aValue = a.volume
          bValue = b.volume
          break
        case 'delta':
          aValue = a.delta
          bValue = b.delta
          break
        case 'confidence':
          aValue = a.confidence
          bValue = b.confidence
          break
        case 'sentiment':
          aValue = a.sentiment.positive
          bValue = b.sentiment.positive
          break
        default:
          aValue = a.volume
          bValue = b.volume
      }

      return state.sortOrder === 'asc' ? aValue - bValue : bValue - aValue
    })

    return filtered
  }, [state.topics, state.searchQuery, state.filters, state.sortBy, state.sortOrder])

  const filteredHashtags = React.useMemo(() => {
    let filtered = state.hashtags

    if (state.searchQuery) {
      filtered = filtered.filter(hashtag =>
        hashtag.hashtag.toLowerCase().includes(state.searchQuery.toLowerCase())
      )
    }

    return filtered
  }, [state.hashtags, state.searchQuery])

  const filteredPosts = React.useMemo(() => {
    let filtered = state.samplePosts

    if (state.searchQuery) {
      filtered = filtered.filter(post =>
        post.title.toLowerCase().includes(state.searchQuery.toLowerCase()) ||
        post.content.toLowerCase().includes(state.searchQuery.toLowerCase())
      )
    }

    return filtered
  }, [state.samplePosts, state.searchQuery])

  const setFilters = (filters: Partial<TrendFilters>) => {
    dispatch({ type: 'SET_FILTERS', payload: filters })
  }

  const setSelectedTopic = (topicId: string | null) => {
    dispatch({ type: 'SET_SELECTED_TOPIC', payload: topicId })
  }

  const setSearchQuery = (query: string) => {
    dispatch({ type: 'SET_SEARCH_QUERY', payload: query })
  }

  const setViewMode = (mode: 'topics' | 'hashtags' | 'posts') => {
    dispatch({ type: 'SET_VIEW_MODE', payload: mode })
  }

  const setSort = (by: 'volume' | 'delta' | 'confidence' | 'sentiment', order: 'asc' | 'desc') => {
    dispatch({ type: 'SET_SORT', payload: { by, order } })
  }

  const resetFilters = () => {
    dispatch({ type: 'RESET_FILTERS' })
  }

  const refreshData = () => {
    dispatch({ type: 'SET_LOADING', payload: true })
    setTimeout(() => {
      generateMockData()
      dispatch({ type: 'SET_LOADING', payload: false })
    }, 1000)
  }

  const toggleSavedItem = (type: 'topics' | 'hashtags' | 'posts', id: string) => {
    dispatch({ type: 'TOGGLE_SAVED_ITEM', payload: { type, id } })
  }

  const isItemSaved = (type: 'topics' | 'hashtags' | 'posts', id: string) => {
    return state.savedItems[type].includes(id)
  }

  const contextValue: TrendContextType = {
    state,
    dispatch,
    filteredTopics,
    filteredHashtags,
    filteredPosts,
    setFilters,
    setSelectedTopic,
    setSearchQuery,
    setViewMode,
    setSort,
    resetFilters,
    refreshData,
    toggleSavedItem,
    isItemSaved
  }

  return (
    <TrendContext.Provider value={contextValue}>
      {children}
    </TrendContext.Provider>
  )
}

export const useTrend = () => {
  const context = useContext(TrendContext)
  if (context === undefined) {
    throw new Error('useTrend must be used within a TrendProvider')
  }
  return context
}
