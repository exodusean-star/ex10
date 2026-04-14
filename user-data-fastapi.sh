#!/bin/bash

# 1. 환경 변수 설정
REGION="ap-south-1"
ACCOUNT_ID="476293896981"
S3_BUCKET="web.sory.cloud"
ECR_REPO="st1/fastapi"
IMAGE_TAG="latest"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE_URI="${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"

# DB 환경 변수 (Secrets Manager에서 가져오기)
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "rds-db-credentials/st1-free-db/board_user/1775106903574" \
  --region ${REGION} \
  --query "SecretString" \
  --output text)

DB_HOST=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])")
DB_USER=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['user'])")
DB_PASSWORD=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
DB_NAME=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])")

# 2. Log 파일 설정
mkdir -p /tmp/log
exec > >(tee -a /tmp/log/user-data.log | logger -t user-data) 2>&1

# 3. 로그 디렉토리 생성
mkdir -p /home/ec2-user/fastapi/logs
chown -R ec2-user:ec2-user /home/ec2-user/fastapi

# 4. ECR 로그인
aws ecr get-login-password --region ${REGION} | \
  docker login --username AWS --password-stdin ${ECR_REGISTRY}

# 5. 이미지 pull 및 기존 컨테이너 정리
docker pull ${IMAGE_URI}
docker stop fastapi-container || true
docker rm fastapi-container || true

# 6. 컨테이너 실행
docker run -d --name fastapi-container -p 8000:8000 \
  -e DB_HOST=${DB_HOST} \
  -e DB_USER=${DB_USER} \
  -e DB_PASSWORD=${DB_PASSWORD} \
  -e DB_NAME=${DB_NAME} \
  -v /home/ec2-user/fastapi/logs:/app/logs \
  ${IMAGE_URI}

# 7. S3 로그 sync cron 등록 (5분마다)
cat > /etc/cron.d/fastapi-log-sync << EOF
*/5 * * * * root aws s3 sync /home/ec2-user/fastapi/logs/ s3://${S3_BUCKET}/logs/fastapi/$(hostname)/ --exclude "*.gz"
EOF
chmod 644 /etc/cron.d/fastapi-log-sync
