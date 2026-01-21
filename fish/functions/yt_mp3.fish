function yt_mp3 --description "Download YouTube video as MP3 audio"
  yt-dlp -x --audio-format mp3 $argv
end
