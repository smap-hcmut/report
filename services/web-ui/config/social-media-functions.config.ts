export interface FunctionField {
  name: string
  label: string
  type: 'text' | 'textarea' | 'select' | 'number'
  required: boolean
  placeholder?: string
  options?: string[]
}

export interface SocialMediaFunction {
  id: string
  label: string
  description: string
  fields: FunctionField[]
  requiresInput: boolean
  outputType: 'object' | 'string' | 'array'
}

export interface SocialMediaFunctions {
  [platform: string]: SocialMediaFunction[]
}

export const socialMediaFunctions: SocialMediaFunctions = {
  facebook: [
    {
      id: 'post',
      label: 'Create Post',
      description: 'Create a new post on Facebook',
      requiresInput: true,
      outputType: 'object',
      fields: [
        {
          name: 'content',
          label: 'Post Content',
          type: 'textarea',
          required: true,
          placeholder: 'Enter post content...'
        },
        {
          name: 'visibility',
          label: 'Visibility',
          type: 'select',
          required: false,
          options: ['Public', 'Friends', 'Only Me']
        }
      ]
    },
    {
      id: 'comment',
      label: 'Post Comment',
      description: 'Comment on a Facebook post',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'post_id',
          label: 'Post ID',
          type: 'text',
          required: true,
          placeholder: 'Enter post ID...'
        },
        {
          name: 'comment_text',
          label: 'Comment Text',
          type: 'textarea',
          required: true,
          placeholder: 'Enter comment...'
        }
      ]
    },
    {
      id: 'like',
      label: 'Like Post',
      description: 'Like a Facebook post',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'post_id',
          label: 'Post ID',
          type: 'text',
          required: true,
          placeholder: 'Enter post ID to like...'
        }
      ]
    },
    {
      id: 'share',
      label: 'Share Post',
      description: 'Share a Facebook post',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'post_id',
          label: 'Post ID',
          type: 'text',
          required: true,
          placeholder: 'Enter post ID to share...'
        },
        {
          name: 'message',
          label: 'Share Message',
          type: 'textarea',
          required: false,
          placeholder: 'Add a message (optional)...'
        }
      ]
    },
    {
      id: 'get_posts',
      label: 'Get Posts',
      description: 'Retrieve Facebook posts',
      requiresInput: false,
      outputType: 'array',
      fields: [
        {
          name: 'limit',
          label: 'Number of Posts',
          type: 'number',
          required: false,
          placeholder: '10'
        }
      ]
    }
  ],
  
  instagram: [
    {
      id: 'post',
      label: 'Create Post',
      description: 'Create a new Instagram post',
      requiresInput: true,
      outputType: 'object',
      fields: [
        {
          name: 'caption',
          label: 'Caption',
          type: 'textarea',
          required: true,
          placeholder: 'Enter caption...'
        },
        {
          name: 'image_url',
          label: 'Image URL',
          type: 'text',
          required: true,
          placeholder: 'https://...'
        }
      ]
    },
    {
      id: 'comment',
      label: 'Post Comment',
      description: 'Comment on an Instagram post',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'post_id',
          label: 'Post ID',
          type: 'text',
          required: true,
          placeholder: 'Enter post ID...'
        },
        {
          name: 'comment_text',
          label: 'Comment Text',
          type: 'textarea',
          required: true,
          placeholder: 'Enter comment...'
        }
      ]
    },
    {
      id: 'like',
      label: 'Like Post',
      description: 'Like an Instagram post',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'post_id',
          label: 'Post ID',
          type: 'text',
          required: true,
          placeholder: 'Enter post ID...'
        }
      ]
    },
    {
      id: 'get_posts',
      label: 'Get Posts',
      description: 'Retrieve Instagram posts',
      requiresInput: false,
      outputType: 'array',
      fields: [
        {
          name: 'limit',
          label: 'Number of Posts',
          type: 'number',
          required: false,
          placeholder: '10'
        }
      ]
    }
  ],
  
  tiktok: [
    {
      id: 'post_video',
      label: 'Post Video',
      description: 'Upload a video to TikTok',
      requiresInput: true,
      outputType: 'object',
      fields: [
        {
          name: 'video_url',
          label: 'Video URL',
          type: 'text',
          required: true,
          placeholder: 'https://...'
        },
        {
          name: 'caption',
          label: 'Caption',
          type: 'textarea',
          required: true,
          placeholder: 'Enter caption...'
        },
        {
          name: 'privacy',
          label: 'Privacy',
          type: 'select',
          required: false,
          options: ['Public', 'Friends', 'Private']
        }
      ]
    },
    {
      id: 'comment',
      label: 'Post Comment',
      description: 'Comment on a TikTok video',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'video_id',
          label: 'Video ID',
          type: 'text',
          required: true,
          placeholder: 'Enter video ID...'
        },
        {
          name: 'comment_text',
          label: 'Comment Text',
          type: 'textarea',
          required: true,
          placeholder: 'Enter comment...'
        }
      ]
    },
    {
      id: 'like',
      label: 'Like Video',
      description: 'Like a TikTok video',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'video_id',
          label: 'Video ID',
          type: 'text',
          required: true,
          placeholder: 'Enter video ID...'
        }
      ]
    },
    {
      id: 'get_videos',
      label: 'Get Videos',
      description: 'Retrieve TikTok videos',
      requiresInput: false,
      outputType: 'array',
      fields: [
        {
          name: 'limit',
          label: 'Number of Videos',
          type: 'number',
          required: false,
          placeholder: '10'
        }
      ]
    }
  ],
  
  linkedin: [
    {
      id: 'post',
      label: 'Create Post',
      description: 'Create a new LinkedIn post',
      requiresInput: true,
      outputType: 'object',
      fields: [
        {
          name: 'content',
          label: 'Post Content',
          type: 'textarea',
          required: true,
          placeholder: 'Share your thoughts...'
        },
        {
          name: 'visibility',
          label: 'Visibility',
          type: 'select',
          required: false,
          options: ['Public', 'Connections', 'Private']
        }
      ]
    },
    {
      id: 'comment',
      label: 'Post Comment',
      description: 'Comment on a LinkedIn post',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'post_id',
          label: 'Post ID',
          type: 'text',
          required: true,
          placeholder: 'Enter post ID...'
        },
        {
          name: 'comment_text',
          label: 'Comment Text',
          type: 'textarea',
          required: true,
          placeholder: 'Enter comment...'
        }
      ]
    },
    {
      id: 'like',
      label: 'Like Post',
      description: 'Like a LinkedIn post',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'post_id',
          label: 'Post ID',
          type: 'text',
          required: true,
          placeholder: 'Enter post ID...'
        }
      ]
    },
    {
      id: 'share',
      label: 'Share Post',
      description: 'Share a LinkedIn post',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'post_id',
          label: 'Post ID',
          type: 'text',
          required: true,
          placeholder: 'Enter post ID...'
        },
        {
          name: 'comment',
          label: 'Your Comment',
          type: 'textarea',
          required: false,
          placeholder: 'Add your thoughts...'
        }
      ]
    },
    {
      id: 'get_posts',
      label: 'Get Posts',
      description: 'Retrieve LinkedIn posts',
      requiresInput: false,
      outputType: 'array',
      fields: [
        {
          name: 'limit',
          label: 'Number of Posts',
          type: 'number',
          required: false,
          placeholder: '10'
        }
      ]
    }
  ],
  
  twitter: [
    {
      id: 'tweet',
      label: 'Post Tweet',
      description: 'Post a new tweet',
      requiresInput: true,
      outputType: 'object',
      fields: [
        {
          name: 'text',
          label: 'Tweet Text',
          type: 'textarea',
          required: true,
          placeholder: "What's happening?"
        }
      ]
    },
    {
      id: 'reply',
      label: 'Reply to Tweet',
      description: 'Reply to a tweet',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'tweet_id',
          label: 'Tweet ID',
          type: 'text',
          required: true,
          placeholder: 'Enter tweet ID...'
        },
        {
          name: 'reply_text',
          label: 'Reply Text',
          type: 'textarea',
          required: true,
          placeholder: 'Your reply...'
        }
      ]
    },
    {
      id: 'retweet',
      label: 'Retweet',
      description: 'Retweet a tweet',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'tweet_id',
          label: 'Tweet ID',
          type: 'text',
          required: true,
          placeholder: 'Enter tweet ID...'
        },
        {
          name: 'comment',
          label: 'Quote Tweet',
          type: 'textarea',
          required: false,
          placeholder: 'Add your comment (optional)...'
        }
      ]
    },
    {
      id: 'like',
      label: 'Like Tweet',
      description: 'Like a tweet',
      requiresInput: false,
      outputType: 'object',
      fields: [
        {
          name: 'tweet_id',
          label: 'Tweet ID',
          type: 'text',
          required: true,
          placeholder: 'Enter tweet ID...'
        }
      ]
    },
    {
      id: 'get_tweets',
      label: 'Get Tweets',
      description: 'Retrieve tweets',
      requiresInput: false,
      outputType: 'array',
      fields: [
        {
          name: 'limit',
          label: 'Number of Tweets',
          type: 'number',
          required: false,
          placeholder: '10'
        }
      ]
    }
  ]
}

export function getSocialMediaFunctions(platform: string): SocialMediaFunction[] {
  const platformKey = platform.toLowerCase()
  return socialMediaFunctions[platformKey] || []
}

export function getFunctionById(platform: string, functionId: string): SocialMediaFunction | undefined {
  const functions = getSocialMediaFunctions(platform)
  return functions.find(f => f.id === functionId)
}
