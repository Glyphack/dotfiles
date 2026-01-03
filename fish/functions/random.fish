# Download a video convert to audio and cut it.
# set url "https://www.youtube.com/watch?v=YsdTVog81eU"; set start_time "00:00:00"; set end_time "00:00:01"; yt-dlp -x --audio-format mp3 -o "temp_download.%(ext)s" $url; and ffmpeg -i temp_download.mp3 -ss $start_time -to $end_time -c copy trimmed_output.mp3; and rm temp_download.mp3
