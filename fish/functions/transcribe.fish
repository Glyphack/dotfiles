function transcribe
    set video_file $argv[1]
    set model_file "ggml-large-v3-q5_0.bin"

    if test -z "$video_file"
        echo "Usage: transcribe <video_file>"
        return 1
    end

    if not test -f "$video_file"
        echo "Error: File '$video_file' not found"
        return 1
    end

    # Get absolute path before changing directory
    set video_path (realpath "$video_file")

    # Move to /tmp
    cd /tmp

    # Download model if it doesn't exist
    if not test -f "$model_file"
        echo "Downloading whisper model..."
        curl -o "$model_file" -L 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-q5_0.bin?download=true'
    end

    # Convert video to wav
    echo "Converting video to wav..."
    ffmpeg -i "$video_path" -ar 16000 input.wav

    # Run whisper transcription
    echo "Transcribing..."
    whisper-cli -m "$model_file" -f input.wav -l fa --task transcribe --output-srt

    # Cleanup
    rm input.wav

    echo "Done! SRT file created in /tmp"
end
