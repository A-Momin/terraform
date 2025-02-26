
invoke_lambda(){
    aws lambda invoke --region=us-east-1 --function-name=hello response.json
}

invoke_lambda2(){
    aws lambda invoke \
    --region us-east-1 \
    --function-name s3 \
    --payload '{"bucket": "test-adequate-parrot","object":"hello.json"}' \
    response.json

    # aws lambda invoke \
    #     --region=us-east-1 \
    #     --function-name=s3 \
    #     --cli-binary-format raw-in-base64-out \
    #     --payload '{"bucket": "test-adequate-parrot","object":"hello.json"}' \
    #     response.json
}

get_apigateway1(){
    curl "https://2448jod6o2.execute-api.us-east-1.amazonaws.com/dev/hello?Name=Aminul"
}

post_apigateway1(){
    curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"Name":"Aminul"}' \
    "https://2448jod6o2.execute-api.us-east-1.amazonaws.com/dev/hello"
}
