function carnext_ssm_hadoop_session
    aws --profile datamesh-dev-developer ssm start-session --parameters='command=["sudo -i -u hadoop"]' --document-name AWS-StartInteractiveCommand --target $argv
end
