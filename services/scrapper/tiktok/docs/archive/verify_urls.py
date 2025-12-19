"""
URL Verification Script - Phase 1
Test what video/audio URLs are available from TikTok's current data structure
"""
import asyncio
import json
import httpx
import re

# Test URL - you can change this to any TikTok video
TEST_VIDEO_URL = "https://www.tiktok.com/@zachking/video/6768504823336815877"


async def scrape_and_extract_urls(video_url: str):
    """
    Scrape a TikTok video and extract all available URLs
    """
    print("=" * 70)
    print(f"TESTING VIDEO: {video_url}")
    print("=" * 70)

    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://www.tiktok.com/',
    }

    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
        print("\n1. Fetching HTML...")
        response = await client.get(video_url, headers=headers)

        if response.status_code != 200:
            print(f"[FAIL] Failed to fetch: HTTP {response.status_code}")
            return

        html = response.text
        print(f"[OK] Fetched {len(html)} characters")

        # Try to find itemStruct data
        print("\n2. Parsing itemStruct data...")
        item_struct = None

        # Try __UNIVERSAL_DATA_FOR_REHYDRATION__
        pattern = r'<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__"[^>]*>(.*?)</script>'
        match = re.search(pattern, html, re.DOTALL)

        if match:
            print("[OK] Found __UNIVERSAL_DATA_FOR_REHYDRATION__")
            try:
                json_str = match.group(1)
                data = json.loads(json_str)

                # Navigate to itemInfo.itemStruct
                default_scope = data.get('__DEFAULT_SCOPE__', {})
                for key, value in default_scope.items():
                    if isinstance(value, dict) and 'itemInfo' in value:
                        item_info = value['itemInfo']
                        if 'itemStruct' in item_info:
                            item_struct = item_info['itemStruct']
                            print(f"[OK] Found itemStruct in key: {key}")
                            break
            except Exception as e:
                print(f"[FAIL] Error parsing __UNIVERSAL_DATA_FOR_REHYDRATION__: {e}")

        # Try __NEXT_DATA__ if not found
        if not item_struct:
            pattern = r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>'
            match = re.search(pattern, html, re.DOTALL)
            if match:
                print("[OK] Found __NEXT_DATA__")
                try:
                    json_str = match.group(1)
                    data = json.loads(json_str)
                    item_struct = data['props']['pageProps']['itemInfo']['itemStruct']
                    print("[OK] Found itemStruct in __NEXT_DATA__")
                except Exception as e:
                    print(f"[FAIL] Error parsing __NEXT_DATA__: {e}")

        # Try SIGI_STATE if not found
        if not item_struct:
            pattern = r'<script id="SIGI_STATE"[^>]*>(.*?)</script>'
            match = re.search(pattern, html, re.DOTALL)
            if match:
                print("[OK] Found SIGI_STATE")
                try:
                    json_str = match.group(1)
                    data = json.loads(json_str)
                    if 'ItemModule' in data:
                        item_module = data['ItemModule']
                        for key, value in item_module.items():
                            item_struct = value
                            print(f"[OK] Found itemStruct in ItemModule: {key}")
                            break
                except Exception as e:
                    print(f"[FAIL] Error parsing SIGI_STATE: {e}")

        if not item_struct:
            print("[FAIL] Could not find itemStruct in any data source")
            return

        # Extract URLs
        print("\n3. Extracting URLs from itemStruct...")
        print("=" * 70)

        # Video URLs
        video_info = item_struct.get('video', {})
        print("\n[VIDEO URLS]")
        print("-" * 70)

        video_urls = {
            'downloadAddr': video_info.get('downloadAddr'),
            'playAddr': video_info.get('playAddr'),
            'cover': video_info.get('cover'),
            'originCover': video_info.get('originCover'),
            'dynamicCover': video_info.get('dynamicCover'),
        }

        for key, url in video_urls.items():
            if url:
                print(f"[OK] {key:15} : {url[:100]}...")
            else:
                print(f"[--] {key:15} : Not available")

        # Audio/Music URLs
        music_info = item_struct.get('music', {})
        print("\n[AUDIO/MUSIC URLS]")
        print("-" * 70)

        music_urls = {
            'playUrl': music_info.get('playUrl'),
            'coverThumb': music_info.get('coverThumb'),
            'coverMedium': music_info.get('coverMedium'),
            'coverLarge': music_info.get('coverLarge'),
        }

        for key, url in music_urls.items():
            if url:
                print(f"[OK] {key:15} : {url[:100]}...")
            else:
                print(f"[--] {key:15} : Not available")

        # Additional metadata
        print("\n[VIDEO METADATA]")
        print("-" * 70)
        print(f"Video ID       : {item_struct.get('id')}")
        print(f"Description    : {item_struct.get('desc', '')[:50]}...")
        print(f"Duration       : {video_info.get('duration')}s")
        print(f"Width x Height : {video_info.get('width')} x {video_info.get('height')}")
        print(f"Music Title    : {music_info.get('title')}")
        print(f"Music Author   : {music_info.get('authorName')}")

        # Test downloading video URL (if available)
        print("\n4. Testing URL Accessibility...")
        print("=" * 70)

        # Test video download URL
        video_download_url = video_info.get('downloadAddr') or video_info.get('playAddr')
        if video_download_url:
            print(f"\n[VIDEO] Testing video URL: {video_download_url[:80]}...")
            try:
                head_response = await client.head(video_download_url, headers=headers, timeout=10.0)
                print(f"[OK] Video URL accessible: HTTP {head_response.status_code}")
                print(f"     Content-Type: {head_response.headers.get('content-type')}")
                print(f"     Content-Length: {head_response.headers.get('content-length')} bytes")
            except Exception as e:
                print(f"[FAIL] Video URL not accessible: {e}")
        else:
            print("[--] No video download URL found")

        # Test audio URL
        audio_url = music_info.get('playUrl')
        if audio_url:
            print(f"\n[AUDIO] Testing audio URL: {audio_url[:80]}...")
            try:
                head_response = await client.head(audio_url, headers=headers, timeout=10.0)
                print(f"[OK] Audio URL accessible: HTTP {head_response.status_code}")
                print(f"     Content-Type: {head_response.headers.get('content-type')}")
                print(f"     Content-Length: {head_response.headers.get('content-length')} bytes")
            except Exception as e:
                print(f"[FAIL] Audio URL not accessible: {e}")
        else:
            print("[--] No audio URL found")

        # Save full itemStruct to file for analysis
        print("\n5. Saving full itemStruct to file...")
        output_file = "itemStruct_analysis.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(item_struct, f, indent=2, ensure_ascii=False)
        print(f"[OK] Saved to: {output_file}")

        print("\n" + "=" * 70)
        print("VERIFICATION COMPLETE")
        print("=" * 70)

        # Summary
        print("\n[SUMMARY]")
        print("-" * 70)
        has_video_url = bool(video_download_url)
        has_audio_url = bool(audio_url)

        print(f"Video download URL available: {'[OK] YES' if has_video_url else '[--] NO'}")
        print(f"Audio/music URL available   : {'[OK] YES' if has_audio_url else '[--] NO'}")

        if has_video_url and has_audio_url:
            print("\n[SUCCESS] GOOD NEWS: Both video and audio URLs are available!")
            print("          We can download audio directly from music.playUrl")
            print("          Fallback to ffmpeg extraction if needed")
        elif has_video_url:
            print("\n[WARN] Only video URL available")
            print("       Will need ffmpeg to extract audio")
        else:
            print("\n[FAIL] No download URLs found - need to investigate further")


async def main():
    """Main entry point"""
    print("\n")
    print("=" * 70)
    print(" " * 15 + "TikTok URL Verification Script")
    print(" " * 27 + "Phase 1")
    print("=" * 70)
    print()

    # You can add multiple test URLs here
    test_urls = [
        TEST_VIDEO_URL,
        # Add more test URLs to verify consistency
        # "https://www.tiktok.com/@username/video/123456789",
    ]

    for url in test_urls:
        await scrape_and_extract_urls(url)
        print("\n" * 2)


if __name__ == "__main__":
    asyncio.run(main())
