.PHONY: package-lambda tf-init tf-apply

package-lambda:
	cd lambda && zip -r lambda.zip start_workflow_lambda.py

tf-init:
	cd terraform && terraform init

tf-apply: package-lambda tf-init
	cd terraform && terraform apply -auto-approve -var="bucket_name=your-unique-bucket-name" -var="prefix=demo" 
