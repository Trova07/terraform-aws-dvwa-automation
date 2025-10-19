# terraform-aws-dvwa-automation

Terraform 기반으로 DVWA(Web), RDS, ELK 등 학습/데모용 인프라를 자동화 배포하는 코드베이스입니다. 서울(`seoul`)과 부산(`busan`) 두 지역 구성을 제공하며, 부산은 서울 구성의 일부를 선택적으로 활용하도록 설계되어 있습니다.

특징
- 지역별 분리: `seoul/`, `busan/` 각각 독립적으로 `terraform init/plan/apply` 가능
- 모듈화 구조: `modules/` 하위에 VPC, Security Group, Launch Template, Auto Scaling, RDS 등 공통 모듈 제공
- 선택적 리소스 생성: 지역별 데이터에 없거나 필요 없는 경우 리소스가 생성되지 않도록 조건부 로직 적용
- 데이터 주도 구성: 각 지역의 `data.yml` 하나로 모든 설정을 관리합니다. 별도의 `.tfvars`나 `variables.tf`를 사용하지 않습니다.

폴더 구성
```
seoul/
  main.tf            # 서울 리전 전체 스택
  data.yml           # 서울 리전 구성 데이터(유일한 입력)

busan/
  main.tf            # 부산 리전 스택 (선택적 RDS/ASG 등)
  data.yml           # 부산 리전 구성 데이터(유일한 입력)

modules/
  vpc/               # VPC, 서브넷, 라우팅, NAT 등
  security_group/    # SG 동적 생성 (ingress/egress 맵 기반)
  keypair/           # 키페어 생성 및 Private Key 출력
  launch_template/   # 여러 개 LT 생성 (for_each), ID/버전 출력
  as/                # 여러 ASG + Target Tracking Policy (조건부 생성)
  rds/               # RDS Subnet Group + RDS Instance + 출력
```

동작 개요
- VPC: 퍼블릭/프라이빗 서브넷과 IGW/NAT, AZ 분산 지원
- SG: `data.yml`의 규칙 맵을 기반으로 동적 인바운드/아웃바운드 생성
- Launch Template: 태그 기반 이름 키로 여러 템플릿 생성, ASG에서 참조
- ASG: `gnuboard`, `dvwa-filebeat`, `elasticsearch1/2` 등 구성. 지역 데이터에 없거나 ID 미지정 시 생성 생략
- RDS: 수동 스냅샷을 우선 사용하도록 옵션 제공(`latest_snapshot` 플래그)
- 보조 리소스: Route53 레코드, Local 파일(Private Key) 등

지역별 차이
- 서울(`seoul`): 모든 컴포넌트(ASG 4종, RDS, Kibana/Suricata 등) 활성 예제 포함
- 부산(`busan`): 경량 구성. `data.yml`에 정의되지 않은 RDS/ASG는 생성하지 않도록 조건부 처리
  - 예) RDS 관련 키(`db_instance`, `rds_subnet_group`)가 없으면 모듈과 레코드 생략
  - 예) ASG의 Launch Template ID가 없거나 그룹 키가 없으면 해당 ASG/정책 생략

준비물
- Terraform v1.6+ (권장)
- AWS 자격 증명(프로파일 또는 환경변수)
- 구성 입력은 오직 `data.yml`입니다. `.tfvars` 및 `variables.tf`는 사용하지 않습니다.
- 사용 AMI/ARN/리소스 ID가 실제 계정/리전에 존재해야 함
  - 예) IAM Instance Profile ARN, Route53 Hosted Zone ID, EBS Volume ID 등은 계정/리전 별로 상이 → 필요 시 변수화 권장

써보기
아래는 서울 리전 예시입니다.

```bash
# (선택) 백엔드 비활성화로 로컬 검증만
cd seoul
terraform init -backend=false -input=false
terraform validate

# 실제 배포(백엔드 사용 시 백엔드 설정 필요)
terraform init
terraform plan
terraform apply
```

부산 리전도 동일합니다.

```bash
cd busan
terraform init -backend=false -input=false
terraform validate

terraform init
terraform plan
terraform apply
```

data.yml에서 자주 보는 키
- `seoul/data.yml` / `busan/data.yml`
  - `network`: CIDR, 서브넷 개수, NAT 수 등
  - `sg_list`: 보안그룹 규칙 맵
  - `launch_template`: LT별 AMI/타입/SG/유저데이터
  - `autoscaling_group`, `autoscaling_policy`: 그룹별 용량/정책
  - (선택) `rds_subnet_group`, `db_instance`: 정의 시에만 RDS 생성

생성 후에 볼 수 있는 것
- VPC ID, 퍼블릭/프라이빗 서브넷 ID 리스트
- SG IDs 맵
- Launch Template IDs/Default Versions
- RDS 주소 (생성 시)

주의할 점
- 하드코딩 값(Hosted Zone ID, IAM Instance Profile ARN, EBS Volume ID 등)은 환경에 맞게 조정 필요. 변수화 추천
- User Data 스크립트에서 AWS CLI 사용 시 AMI에 CLI가 설치되어 있어야 함 (또는 설치 단계 추가)
- 특정 ASG 리소스는 퍼블릭 서브넷 인덱스 접근(예: `[0]`, `[1]`)을 합니다. 최소 2개의 퍼블릭 서브넷이 존재해야 합니다.
- `terraform destroy` 시 RDS 스냅샷 관련 정책(`skip_final_snapshot`)을 확인하고 데이터 유실 방지에 유의하십시오.

라이선스/용도
이 레포지토리는 학습/데모 목적의 예시 코드입니다. 기업/프로덕션 사용 시 보안/운영 정책에 맞춘 추가 검토가 필요합니다.
