# terraform-aws-dvwa-automation

IaC(Terraform)로 서울(ap-northeast-2)과 부산 환경을 구성해 DVWA/Elasticsearch/Kibana/RDS 등을 자동화합니다. 각 환경은 독립 실행 디렉터리(seoul, busan)로 분리되어 있으며 공통 모듈은 `modules/`에 있습니다.

## 구성 및 버전
- Terraform Core: >= 1.3 (권장: 1.13.x)
- Providers:
  - hashicorp/aws ~> 5.x
  - hashicorp/tls ~> 4.x (키페어 생성)
  - hashicorp/local ~> 2.x (로컬 파일 출력)
- 상태 저장: 각 스택 디렉터리 내 로컬 상태(`terraform.tfstate`)

## 디렉터리 구조
- `seoul/`: 서울 스택. VPC, SG, Key Pair, Launch Template, EC2, ASG, RDS, 트래픽 미러 등 포함
- `busan/`: 부산 스택. 서울과 유사하나 입력값/활성 리소스 다름
- `modules/`: 재사용 모듈 모음
  - `vpc/`: VPC, 서브넷, IGW, NAT, 라우팅
  - `security_group/`: SG를 맵 형태 입력으로 일괄 생성
  - `keypair/`: tls provider로 키 생성, AWS Key Pair와 로컬 개인키 파일 출력
  - `launch_template/`: EC2 Launch Template 집합 생성
  - `ec2/`: public/private EC2 인스턴스 및 Route53 레코드
  - `as/`: Auto Scaling Group과 TargetTracking Policy
  - `rds/`: Subnet Group, DB Instance(스냅샷 복구 옵션 포함)

참고: 과거 단일 EC2 예시 스택이었던 `elasticsearch/`는 현재 레포에서 제거되었습니다(필요 시 별도 브랜치/디렉터리로 복원하여 사용하세요).

## 수동 VPC Peering 명시(중요)
- 서울 VPC ↔ 부산 VPC 간 VPC Peering은 Terraform 외부에서 “수동”으로 생성/연결/라우팅 설정했습니다.
  - Peering 연결 생성 및 승인
  - 각 VPC 라우트테이블에 상대 CIDR로의 경로 추가
  - SG/NACL 통신 허용 규칙 검토
- 위 작업은 Terraform 상태에 포함되지 않으므로, 드리프트 관리/문서화가 필요합니다.

## 사용 방법
각 스택 디렉터리에서 독립적으로 초기화/계획/적용합니다.

### 1) seoul
- 설정: `seoul/data.yml`
- 실행:
```bash
cd seoul
terraform init -upgrade
terraform validate
terraform plan
terraform apply
```

### 2) busan
- 설정: `busan/data.yml`
- 실행은 `seoul`과 동일합니다.

## 모듈 입력/출력 개요(발췌)
- `modules/vpc`
  - 입력: `region`, `region_name`, `az_list`, `number_of_azs`, `cidr_block`, `subnet_bits`, `number_of_public_subnets`, `number_of_private_subnets`, `number_of_nat_gws`
  - 출력: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`
- `modules/security_group`
  - 입력: `sg_list(map)`, `vpc_id`
  - 출력: SG ID 맵
- `modules/keypair`
  - 입력: `key_info(algorithm, rsa_bits)`, `region_name`
  - 출력: `private_key`(로컬 파일 저장), `key_name`
- `modules/launch_template`
  - 입력: `launch_template(map)`, `sg_ids`
  - 출력: `launch_template_ids(map)`
- `modules/ec2`
  - 입력: `region_name`, `public/private_subnet_ids`, `sg_ids`, `key_name`, `ec2_instances(map)`
  - 출력: 퍼블릭 인스턴스 IP 기반의 Route53 레코드 등
- `modules/as`
  - 입력: `public_subnet_ids`, `autoscaling_group(map)`, `autoscaling_policy`, `launch_template_ids`, 특정 템플릿 id들(`id_gnuboard`, `id_dvwa`, `id_elasticsearch1`, `id_elasticsearch2`)
- `modules/rds`
  - 입력: `sg_ids`, `db_instance`, `rds_subnet_group`, `subnet_ids`
  - 특징: 최신 수동 스냅샷 복구 옵션 지원

## 주의사항
- 민감정보(개인키 등)는 커밋 금지. `.gitignore`로 제외하세요.
- 로컬 상태 사용으로 협업 충돌 위험이 있으니, S3+DynamoDB 백엔드 전환을 검토하세요.
- AMI ID, Hosted Zone ID, IAM Profile ARN 등은 환경에 맞게 변경해야 합니다.
- 퍼블릭 서브넷 인덱스 참조(`[0]`, `[1]`)가 있는 ASG는 최소 2개의 퍼블릭 서브넷이 필요합니다.

---
문의/개선 포인트는 이슈 또는 PR로 제안해 주세요.
