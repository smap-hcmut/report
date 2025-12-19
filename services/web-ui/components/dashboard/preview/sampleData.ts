/**
 * Sample data for project preview
 * Based on: docs/DRY-RUN-DATA-FLOW.md (lines 502-573)
 *
 * This data is shown to users before they trigger the actual preview
 * to demonstrate what kind of data will be displayed.
 */

import { DryRunOuterPayload, DryRunContent } from '@/lib/types/dryrun'

// Sample TikTok posts
const SAMPLE_TIKTOK_POSTS: DryRunContent[] = [
      {
        meta: {
          id: '7234567890123456789',
          platform: 'tiktok',
          job_id: '550e8400-e29b-41d4-a716-446655440000',
          crawled_at: '2024-01-15T10:30:00Z',
          published_at: '2024-01-10T08:00:00Z',
          permalink: 'https://www.tiktok.com/@user/video/7234567890123456789',
          keyword_source: 'cooking tutorial',
          lang: 'vi',
          region: 'VN',
          pipeline_version: 'crawler_tiktok_v3',
          fetch_status: 'success',
          fetch_error: null
        },
        content: {
          text: 'Easy cooking tutorial! #cooking #food',
          duration: 45,
          hashtags: ['cooking', 'food'],
          sound_name: 'Original Sound - User',
          category: 'Food',
          media: {
            type: 'audio',
            video_path: '',
            audio_path: 'tiktok/job-abc-123/7234567890123456789.mp3',
            downloaded_at: '2024-01-15T10:31:00Z'
          },
          transcription: 'Today I will show you how to cook...'
        },
        interaction: {
          views: 150000,
          likes: 12000,
          comments_count: 450,
          shares: 890,
          saves: 2300,
          engagement_rate: 0.0893,
          updated_at: '2024-01-15T10:30:00Z'
        },
        author: {
          id: 'user123',
          name: 'Cooking Master',
          username: 'cookingmaster',
          followers: 500000,
          following: 123,
          likes: 5000000,
          videos: 234,
          is_verified: true,
          bio: 'Professional chef sharing recipes',
          avatar_url: null,
          profile_url: 'https://www.tiktok.com/@cookingmaster'
        },
        comments: [
          {
            id: 'comment123',
            parent_id: null,
            post_id: '7234567890123456789',
            user: {
              id: null,
              name: 'FoodLover',
              avatar_url: null
            },
            text: 'Amazing recipe!',
            likes: 45,
            replies_count: 2,
            published_at: '2024-01-10T09:00:00Z',
            is_author: false,
            media: null
          }
        ]
      },
      {
        meta: {
          id: '7234567890123456790',
          platform: 'tiktok',
          job_id: '550e8400-e29b-41d4-a716-446655440000',
          crawled_at: '2024-01-15T11:00:00Z',
          published_at: '2024-01-12T14:30:00Z',
          permalink: 'https://www.tiktok.com/@user2/video/7234567890123456790',
          keyword_source: 'food recipe',
          lang: 'vi',
          region: 'VN',
          pipeline_version: 'crawler_tiktok_v3',
          fetch_status: 'success',
          fetch_error: null
        },
        content: {
          text: '3 món ăn nhanh cho bữa sáng 🍳☕ #food #breakfast #quickrecipe',
          duration: 60,
          hashtags: ['food', 'breakfast', 'quickrecipe'],
          sound_name: 'Trending Sound - Morning Vibes',
          category: 'Food',
          transcription: 'Chào mọi người, hôm nay mình sẽ chia sẻ 3 món ăn sáng siêu nhanh...'
        },
        interaction: {
          views: 250000,
          likes: 18500,
          comments_count: 620,
          shares: 1200,
          saves: 3400,
          engagement_rate: 0.0948,
          updated_at: '2024-01-15T11:00:00Z'
        },
        author: {
          id: 'user456',
          name: 'Chef Annie',
          username: 'chefannie',
          followers: 750000,
          following: 89,
          likes: 8500000,
          videos: 456,
          is_verified: true,
          bio: 'Food blogger & Recipe creator 🍜',
          avatar_url: null,
          profile_url: 'https://www.tiktok.com/@chefannie'
        },
        comments: [
          {
            id: 'comment456',
            parent_id: null,
            post_id: '7234567890123456790',
            user: {
              id: null,
              name: 'MorningPerson',
              avatar_url: null
            },
            text: 'Perfect for busy mornings! 😍',
            likes: 120,
            replies_count: 5,
            published_at: '2024-01-12T15:00:00Z',
            is_author: false,
            media: null
          },
          {
            id: 'comment457',
            parent_id: null,
            post_id: '7234567890123456790',
            user: {
              id: 'user456',
              name: 'Chef Annie',
              avatar_url: null
            },
            text: 'Thank you! Try it and let me know 💕',
            likes: 89,
            replies_count: 0,
            published_at: '2024-01-12T16:00:00Z',
            is_author: true,
            media: null
          }
        ]
      }
    ]

// Sample Facebook posts
const SAMPLE_FACEBOOK_POSTS: DryRunContent[] = [
  {
    meta: {
      id: 'fb_123456789',
      platform: 'facebook',
      job_id: '550e8400-e29b-41d4-a716-446655440001',
      crawled_at: '2024-01-15T10:00:00Z',
      published_at: '2024-01-14T09:30:00Z',
      permalink: 'https://facebook.com/posts/123456789',
      keyword_source: 'cooking tutorial',
      lang: 'vi',
      region: 'VN',
      pipeline_version: 'crawler_facebook_v1',
      fetch_status: 'success',
      fetch_error: null
    },
    content: {
      text: 'Chia sẻ công thức làm bánh mì ngon tuyệt! 🥖\n\nSáng nay mình thử làm bánh mì tại nhà và kết quả ngoài mong đợi. Các bạn có thể thử làm theo công thức này nhé!\n\nNguyên liệu:\n- 500g bột mì\n- 300ml nước ấm\n- 1 thìa men\n- 2 thìa đường\n- 1 thìa muối\n\nCách làm thì xem video chi tiết ở link trong comment nhé! 👇',
      hashtags: ['cooking', 'bread', 'homemade', 'recipe'],
      category: 'Food & Cooking',
      title: null
    },
    interaction: {
      views: 45000,
      likes: 3200,
      comments_count: 156,
      shares: 89,
      engagement_rate: 0.0767,
      updated_at: '2024-01-15T10:00:00Z'
    },
    author: {
      id: 'fb_user_001',
      name: 'Bếp Nhà Mình',
      username: 'bepnhaminh',
      followers: 125000,
      following: 234,
      likes: 0,
      videos: 0,
      is_verified: true,
      bio: 'Chia sẻ công thức nấu ăn gia đình 👨‍🍳',
      avatar_url: null,
      profile_url: 'https://facebook.com/bepnhaminh'
    },
    comments: [
      {
        id: 'fb_comment_001',
        parent_id: null,
        post_id: 'fb_123456789',
        user: {
          id: null,
          name: 'Nguyễn Văn A',
          avatar_url: null
        },
        text: 'Nhìn ngon quá! Tối nay về thử làm ngay 😋',
        likes: 45,
        replies_count: 2,
        published_at: '2024-01-14T10:00:00Z',
        is_author: false,
        media: null
      },
      {
        id: 'fb_comment_002',
        parent_id: null,
        post_id: 'fb_123456789',
        user: {
          id: null,
          name: 'Trần Thị B',
          avatar_url: null
        },
        text: 'Cho mình hỏi men nở hay men nấu bánh vậy ạ?',
        likes: 12,
        replies_count: 1,
        published_at: '2024-01-14T11:30:00Z',
        is_author: false,
        media: null
      },
      {
        id: 'fb_comment_003',
        parent_id: 'fb_comment_002',
        post_id: 'fb_123456789',
        user: {
          id: 'fb_user_001',
          name: 'Bếp Nhà Mình',
          avatar_url: null
        },
        text: 'Dùng men nở nha bạn! 😊',
        likes: 8,
        replies_count: 0,
        published_at: '2024-01-14T12:00:00Z',
        is_author: true,
        media: null
      }
    ]
  },
  {
    meta: {
      id: 'fb_123456790',
      platform: 'facebook',
      job_id: '550e8400-e29b-41d4-a716-446655440001',
      crawled_at: '2024-01-15T11:30:00Z',
      published_at: '2024-01-13T16:00:00Z',
      permalink: 'https://facebook.com/posts/123456790',
      keyword_source: 'food recipe',
      lang: 'vi',
      region: 'VN',
      pipeline_version: 'crawler_facebook_v1',
      fetch_status: 'success',
      fetch_error: null
    },
    content: {
      text: '5 MẸO NẤU ĂN GIÚP TIẾT KIỆM THỜI GIAN 🕐⚡\n\n1️⃣ Chuẩn bị nguyên liệu trước\n2️⃣ Sử dụng nồi áp suất\n3️⃣ Nấu nhiều món cùng lúc\n4️⃣ Dùng gia vị có sẵn\n5️⃣ Meal prep cuối tuần\n\nCác mẹo này giúp mình tiết kiệm được 50% thời gian nấu ăn mỗi ngày! Các bạn đã thử mẹo nào chưa? Share kinh nghiệm nhé! 💬👇',
      hashtags: ['cookingtips', 'timesaving', 'kitchenhacks'],
      category: 'Food & Cooking',
      title: null
    },
    interaction: {
      views: 68000,
      likes: 5400,
      comments_count: 289,
      shares: 234,
      engagement_rate: 0.0882,
      updated_at: '2024-01-15T11:30:00Z'
    },
    author: {
      id: 'fb_user_002',
      name: 'Bếp Của Mẹ',
      username: 'bepcuame',
      followers: 280000,
      following: 156,
      likes: 0,
      videos: 0,
      is_verified: true,
      bio: 'Hướng dẫn nấu ăn đơn giản cho mọi nhà 🏠',
      avatar_url: null,
      profile_url: 'https://facebook.com/bepcuame'
    },
    comments: [
      {
        id: 'fb_comment_004',
        parent_id: null,
        post_id: 'fb_123456790',
        user: {
          id: null,
          name: 'Phạm Văn C',
          avatar_url: null
        },
        text: 'Mẹo số 5 rất hay! Mình áp dụng rồi, tiết kiệm cả thời gian lẫn tiền bạc 👍',
        likes: 156,
        replies_count: 3,
        published_at: '2024-01-13T17:00:00Z',
        is_author: false,
        media: null
      }
    ]
  }
]

// Sample YouTube videos
const SAMPLE_YOUTUBE_POSTS: DryRunContent[] = [
  {
    meta: {
      id: 'yt_video_001',
      platform: 'youtube',
      job_id: '550e8400-e29b-41d4-a716-446655440002',
      crawled_at: '2024-01-15T09:00:00Z',
      published_at: '2024-01-10T10:00:00Z',
      permalink: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      keyword_source: 'cooking tutorial',
      lang: 'vi',
      region: 'VN',
      pipeline_version: 'crawler_youtube_v2',
      fetch_status: 'success',
      fetch_error: null
    },
    content: {
      text: 'Trong video này, mình sẽ hướng dẫn các bạn cách làm món phở bò chuẩn vị Hà Nội ngay tại nhà. Công thức này mình học được từ người thầy có 30 năm kinh nghiệm.\n\nNguyên liệu chi tiết:\n- 1kg xương ống\n- 500g thịt bò\n- Gia vị: hành, gừng, hồi, quế...\n\nThời gian nấu: 3-4 tiếng\nĐộ khó: Trung bình\n\nNếu các bạn thích video này thì đừng quên like, share và subscribe kênh để ủng hộ mình nhé! 🙏',
      title: 'Cách Nấu PHỞ BÒ Chuẩn Vị Hà Nội Tại Nhà | Bí Quyết Nước Dùng Trong Veo',
      duration: 1245,
      hashtags: ['pho', 'cooking', 'vietnamese food', 'recipe'],
      category: 'Food & Cooking',
      transcription: 'Xin chào các bạn, hôm nay mình sẽ hướng dẫn các bạn cách nấu phở bò...'
    },
    interaction: {
      views: 450000,
      likes: 28000,
      comments_count: 1240,
      shares: 0,
      engagement_rate: 0.0651,
      updated_at: '2024-01-15T09:00:00Z'
    },
    author: {
      id: 'yt_channel_001',
      name: 'Món Ngon Mỗi Ngày',
      username: 'monngonmoingay',
      followers: 1250000,
      following: 0,
      likes: 0,
      videos: 342,
      is_verified: true,
      bio: 'Kênh chia sẻ công thức nấu ăn ngon mỗi ngày',
      avatar_url: null,
      profile_url: 'https://www.youtube.com/@monngonmoingay',
      country: 'VN',
      total_view_count: 125000000
    },
    comments: [
      {
        id: 'yt_comment_001',
        parent_id: null,
        post_id: 'yt_video_001',
        user: {
          id: null,
          name: '@foodlover2024',
          avatar_url: null
        },
        text: 'Video quá chi tiết và dễ hiểu! Cuối tuần này mình sẽ thử làm ngay. Cảm ơn bạn rất nhiều! 😊',
        likes: 234,
        replies_count: 5,
        published_at: '2024-01-10T12:00:00Z',
        is_author: false,
        media: null,
        is_favorited: false
      },
      {
        id: 'yt_comment_002',
        parent_id: null,
        post_id: 'yt_video_001',
        user: {
          id: 'yt_channel_001',
          name: '@monngonmoingay',
          avatar_url: null
        },
        text: 'Cảm ơn bạn đã ủng hộ! Chúc bạn thành công nhé! ❤️',
        likes: 89,
        replies_count: 0,
        published_at: '2024-01-10T14:00:00Z',
        is_author: true,
        media: null,
        is_favorited: true
      },
      {
        id: 'yt_comment_003',
        parent_id: null,
        post_id: 'yt_video_001',
        user: {
          id: null,
          name: '@chefwannabe',
          avatar_url: null
        },
        text: 'Mình đã làm theo và gia đình khen ngon lắm! Nước dùng thơm và trong veo như ngoài hàng. 10/10! 👍',
        likes: 456,
        replies_count: 12,
        published_at: '2024-01-11T09:30:00Z',
        is_author: false,
        media: null,
        is_favorited: false
      }
    ]
  },
  {
    meta: {
      id: 'yt_video_002',
      platform: 'youtube',
      job_id: '550e8400-e29b-41d4-a716-446655440002',
      crawled_at: '2024-01-15T10:30:00Z',
      published_at: '2024-01-12T15:00:00Z',
      permalink: 'https://www.youtube.com/watch?v=abc123xyz',
      keyword_source: 'food recipe',
      lang: 'vi',
      region: 'VN',
      pipeline_version: 'crawler_youtube_v2',
      fetch_status: 'success',
      fetch_error: null
    },
    content: {
      text: '10 MÓN ĂN NHANH CHO NGƯỜI BẬN RỘN 🍜⚡\n\nBạn thường xuyên không có thời gian nấu ăn? Video này dành cho bạn!\n\nDanh sách món:\n1. Mì xào giòn (10 phút)\n2. Cơm chiên dương châu (15 phút)\n3. Gà xào xả ớt (20 phút)\n4. Canh chua cá (15 phút)\n5. Thịt kho tàu (25 phút)\n...\n\nTất cả đều là món dễ làm, nguyên liệu sẵn có và siêu ngon!\n\nTimestamp:\n0:00 - Intro\n1:23 - Món 1: Mì xào giòn\n4:56 - Món 2: Cơm chiên\n...\n\n#quickrecipes #easycooking #fastfood',
      title: '10 Món Ăn Nhanh Dưới 30 Phút Cho Người Bận Rộn | Đơn Giản Mà Ngon',
      duration: 892,
      hashtags: ['quickrecipes', 'easycooking', 'fastfood', 'vietnamese'],
      category: 'Howto & Style',
      transcription: 'Xin chào mọi người! Hôm nay mình sẽ chia sẻ 10 món ăn nhanh...'
    },
    interaction: {
      views: 680000,
      likes: 42000,
      comments_count: 1850,
      shares: 0,
      engagement_rate: 0.0644,
      updated_at: '2024-01-15T10:30:00Z'
    },
    author: {
      id: 'yt_channel_002',
      name: 'Bếp Của Bạn',
      username: 'bepcuaban',
      followers: 890000,
      following: 0,
      likes: 0,
      videos: 256,
      is_verified: true,
      bio: 'Nấu ăn đơn giản - Ngon từng bữa',
      avatar_url: null,
      profile_url: 'https://www.youtube.com/@bepcuaban',
      country: 'VN',
      total_view_count: 89000000
    },
    comments: [
      {
        id: 'yt_comment_004',
        parent_id: null,
        post_id: 'yt_video_002',
        user: {
          id: null,
          name: '@busymom123',
          avatar_url: null
        },
        text: 'Video này cứu cánh cho những người bận rộn như mình! Đã save vào playlist để xem lại nhiều lần 📌',
        likes: 567,
        replies_count: 8,
        published_at: '2024-01-12T17:00:00Z',
        is_author: false,
        media: null,
        is_favorited: false
      },
      {
        id: 'yt_comment_005',
        parent_id: null,
        post_id: 'yt_video_002',
        user: {
          id: null,
          name: '@studentlife',
          avatar_url: null
        },
        text: 'Là sinh viên ở trọ thì video này quá hữu ích! Món nào cũng dễ làm và rẻ nữa 🎓',
        likes: 423,
        replies_count: 15,
        published_at: '2024-01-13T10:00:00Z',
        is_author: false,
        media: null,
        is_favorited: false
      }
    ]
  }
]

// Combined sample data
export const SAMPLE_PREVIEW_DATA: DryRunOuterPayload = {
  type: 'dryrun_result',
  job_id: 'sample-preview-job-id',
  platform: 'tiktok',
  status: 'success',
  payload: {
    content: [
      ...SAMPLE_TIKTOK_POSTS,
      ...SAMPLE_FACEBOOK_POSTS,
      ...SAMPLE_YOUTUBE_POSTS
    ],
    errors: []
  }
}
