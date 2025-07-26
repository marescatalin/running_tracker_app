GO_IMG=docker run --rm -e GOOS=linux -e GOARCH=arm64 -v "$(shell echo `pwd`)/runner-tracker-app-lambda":/runner-tracker-app-lambda -w /runner-tracker-app-lambda golang:1.24
TF_IMG=docker run --rm -e AWS_PROFILE=catalin_dev -v "$(shell echo `pwd` )":/usr/terrafresh -v ${HOME}/.aws:/root/.aws -w /usr/terrafresh hashicorp/terraform:1.4.6 -chdir=terraform

# Go/Lambda
fmt:
	$(GO_IMG) go fmt

build_lambda_zip: clean_go_build go_build_lambda
	zip -j lambda.zip runner-tracker-app-lambda/bootstrap

go_build_lambda:
	$(GO_IMG) go build -tags lambda.norpc -o bootstrap main.go

clean_go_build:
	rm -f runner-tracker-app-lambda/bootstrap
	rm -f runner-tracker-app-lambda/lambda.zip
	
# TF
fmt_tf:
	$(TF_IMG) fmt -recursive

validate_tf:
	$(TF_IMG) validate

init_tf:
	$(TF_IMG) init -reconfigure

plan_tf:
	$(TF_IMG) plan 

apply_tf:
	$(TF_IMG) apply -auto-approve

destroy_tf:
	$(TF_IMG) destroy -auto-approve
