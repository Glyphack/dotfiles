function l --description "Generate and execute fish shell commands using AI (GPT-4o)"
    set command (uvx llm --model gpt-4o --system "In the following conversation, you are asked to return a unix command that performs what is asked.The command you return must be compatible with fish shell. Use the latest documentations and tools and do not suggest out dated solutions. Return only the command without explanation. Do not add backticks to the command. The commands must run in fish shell use fish shell syntax and make sure it's valid and works." $argv)

    echo "$command" | gum format --type code
    echo $command | pbcopy

    set escaped_command (string escape --style=url $command)
    echo "Command copied to clipboard. Explain: http://explainshell.com/explain?cmd=$escaped_command"
end
