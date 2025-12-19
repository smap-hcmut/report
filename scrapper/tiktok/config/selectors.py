"""
TikTok DOM Selectors
Cập nhật khi TikTok thay đổi DOM structure
"""

# TikTok Selectors
SELECTORS = {
    # Video page selectors
    'video': {
        'description': [
            'h1[data-e2e="browse-video-desc"]',
            'div.tiktok-j2a19r-SpanText',
            'span.tiktok-j2a19r-SpanText'
        ],
        'view_count': [
            'strong[data-e2e="browse-video-view-count"]',
            'strong.video-count'
        ],
        'like_count': [
            'strong[data-e2e="like-count"]',
            'strong[data-e2e="browse-like-count"]'
        ],
        'comment_count': [
            'strong[data-e2e="comment-count"]',
            'strong[data-e2e="browse-comment-count"]'
        ],
        'share_count': [
            'strong[data-e2e="share-count"]',
            'strong[data-e2e="browse-share-count"]'
        ],
        'save_count': [
            'strong[data-e2e="undefined-count"]',
            'strong[data-e2e="browse-collect-count"]'
        ],
        'upload_time': [
            'span[data-e2e="browser-nickname"] ~ span',
            'span.video-meta-date'
        ],
        'sound_name': [
            'h4[data-e2e="browse-sound-name"]',
            'div.music-info a'
        ],
        'hashtags': [
            'a[href*="/tag/"]',
            'strong[data-e2e="search-common-link"]'
        ]
    },

    # Creator profile selectors
    'creator': {
        'username': [
            'h1[data-e2e="user-title"]',
            'h2.share-title'
        ],
        'display_name': [
            'h2[data-e2e="user-subtitle"]',
            'h1.share-sub-title'
        ],
        'bio': [
            'h2[data-e2e="user-bio"]',
            'div.share-desc'
        ],
        'follower_count': [
            'strong[data-e2e="followers-count"]',
            'div[data-e2e="followers-count"]'
        ],
        'following_count': [
            'strong[data-e2e="following-count"]',
            'div[data-e2e="following-count"]'
        ],
        'total_likes': [
            'strong[data-e2e="likes-count"]',
            'div[data-e2e="likes-count"]'
        ],
        'verified': [
            'svg[data-e2e="verified-icon"]',
            'path[d*="M10.5"]'
        ]
    },

    # Comment selectors
    'comment': {
        'container': [
            'div[data-e2e="comment-item"]',
            'div.comment-item'
        ],
        'text': [
            'p[data-e2e="comment-level-1"]',
            'span.comment-text'
        ],
        'commenter_name': [
            'span[data-e2e="comment-username-1"]',
            'a.comment-username'
        ],
        'timestamp': [
            'span[data-e2e="comment-time"]',
            'span.comment-time'
        ],
        'like_count': [
            'span[data-e2e="comment-like-count"]',
            'span.comment-like-count'
        ],
        'view_more_button': [
            'p[data-e2e="view-more-comment"]',
            'button.view-more'
        ]
    }
}
