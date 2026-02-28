function ,v --description "Video/media workflow helper commands"
    if test (count $argv) -eq 0
        echo "Usage: ,v <command> [args]"
        echo ""
        echo "Commands:"
        echo "  dl <url> [--trim start-end]   Download video via yt-dlp (--trim to cut)"
        echo "  mp3 <file|url>                Convert video/URL to MP3"
        echo "  compress <file>               Compress video with H.265"
        echo "  tovid <file>                  Convert MP3 to video with blue background"
        echo "  transcribe <file>             Transcribe to SRT via whisper"
        return 1
    end

    set subcmd $argv[1]
    set -e argv[1]

    switch $subcmd
        case dl
            if test (count $argv) -eq 0
                echo "Usage: ,v dl <url> [--trim start-end]"
                return 1
            end

            set url $argv[1]
            set -e argv[1]

            set trim_arg ""
            if set idx (contains -i -- --trim $argv)
                set trim_val $argv[(math $idx + 1)]
                set -e argv[(math $idx + 1)]
                set -e argv[$idx]
                set trim_arg "--download-sections" "*$trim_val"
            end

            if test -n "$trim_arg"
                yt-dlp $trim_arg --force-keyframes-at-cuts -o "%(title)s.%(ext)s" "$url"
            else
                yt-dlp -o "%(title)s.%(ext)s" "$url"
            end

        case mp3
            if test (count $argv) -eq 0
                echo "Usage: ,v mp3 <file|url>"
                return 1
            end

            set input_file $argv[1]
            set url $input_file

            if string match -q 'https*' $input_file
                set temp_video "/tmp/vid_to_mp3_"(random)
                yt-dlp -o $temp_video "$url" >/dev/null 2>&1

                if test $status -ne 0
                    echo "Error: Download failed" >&2
                    return 1
                end

                set downloaded_file (ls $temp_video.* 2>/dev/null | head -n 1)

                if test -z "$downloaded_file"
                    echo "Error: Download failed" >&2
                    return 1
                end

                set input_file $downloaded_file
                set output_file (yt-dlp --get-filename -o '%(title)s.mp3' "$url" 2>/dev/null)
            else
                set output_file (path change-extension 'mp3' $input_file)
            end

            ffmpeg -i $input_file -vn -acodec mp3 $output_file >/dev/null 2>&1

            if test $status -ne 0
                echo "Error: Conversion failed" >&2
                if test -n "$downloaded_file"
                    rm -f $downloaded_file
                end
                return 1
            end

            if test -n "$downloaded_file"
                rm -f $downloaded_file
            end

            echo $output_file

        case compress
            if test (count $argv) -eq 0
                echo "Usage: ,v compress <file>"
                return 1
            end

            ffmpeg -i $argv[1] -vcodec libx265 -crf 28 -preset medium -acodec aac -b 128k $argv[1].mp4

        case tovid
            if test (count $argv) -eq 0
                echo "Usage: ,v tovid <file>"
                return 1
            end

            ffmpeg -f lavfi -i color=c=blue:s=1280x720 -i $argv[1] -shortest -fflags +shortest output.mp4

        case transcribe
            if test (count $argv) -eq 0
                echo "Usage: ,v transcribe <file>"
                return 1
            end

            set video_file $argv[1]
            set model_file "ggml-large-v3-q5_0.bin"

            if not test -f "$video_file"
                echo "Error: File '$video_file' not found"
                return 1
            end

            set video_path (realpath "$video_file")

            cd /tmp

            if not test -f "$model_file"
                echo "Downloading whisper model..."
                curl -o "$model_file" -L 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-q5_0.bin?download=true'
            end

            echo "Converting video to wav..."
            ffmpeg -i "$video_path" -ar 16000 input.wav

            echo "Transcribing..."
            whisper-cli -m "$model_file" -f input.wav -l fa --task transcribe --output-srt

            rm input.wav

            echo "Done! SRT file created in /tmp"

        case '*'
            echo "Unknown command: $subcmd"
            ,v
            return 1
    end
end
