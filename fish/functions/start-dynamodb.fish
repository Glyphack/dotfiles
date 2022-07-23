function start-dynamodb
    set DPath ~/bin/DynamoDBLocal/
    java -Djava.library.path=$DPath/DynamoDBLocal_lib -jar $DPath/DynamoDBLocal.jar -sharedDb
end
