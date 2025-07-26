build:
	mvn clean package
	docker buildx build --platform linux/amd64,linux/arm64 -t runner-tracker-app-backend .

run:
	docker run --rm -it -e AWS_PROFILE="catalin_dev" -p 8080:8080 --network="runner-tracker-app-network" -v ${HOME}/.aws:/root/.aws --name=runner-tracker-app-backend runner-tracker-app-backend

login:
	aws ecr get-login-password --profile catalin_dev --region eu-west-2 | docker login --username AWS --password-stdin 574339526148.dkr.ecr.eu-west-2.amazonaws.com

tag-image:
	docker tag runner-tracker-app-frontend:latest 574339526148.dkr.ecr.eu-west-2.amazonaws.com/runner-tracker-app:frontend
	docker tag runner-tracker-app-backend:latest 574339526148.dkr.ecr.eu-west-2.amazonaws.com/runner-tracker-app:backend

push-image:
	docker push  574339526148.dkr.ecr.eu-west-2.amazonaws.com/runner-tracker-app:frontend
	docker push  574339526148.dkr.ecr.eu-west-2.amazonaws.com/runner-tracker-app:backend

test:
	curl ecs-load-balancer-152199329.eu-west-2.elb.amazonaws.com:8080/api/distance