function get
    set command (llm --system "In the following conversation, you are asked to return a unix command that performs what is asked. Return only the command without explanation. Do not add backticks to the command."  --model mistral-7b-instruct-v0 $argv)
    echo $command | pbcopy
    echo "command is $command"

    set escaped_command (string escape --style=url "$command")
    echo "Command copied to clipboard. Explain: http://explainshell.com/explain?cmd=$escaped_command"
end
