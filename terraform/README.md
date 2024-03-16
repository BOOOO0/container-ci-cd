# Terraform으로 VPC 환경의 EKS 클러스터 구축

- Route53은 다른 팀원이 구성할 예정

- 로드밸런서도 EKS를 쓰기 때문에 사용할 필요가 없고

- S3도 이미지를 통해 빌드할 것이기 때문에 생성할 필요 없고

- EKS에 집중하면 될 듯

- Jenkins 서버는 도커가 있어야 할 것 같고 도커 로그인은 Jenkinsfile에서 하면 될 것 같다.

- 도커 외에 다른 빌드 도구는 필요가 없을 것 같다.

- DB는 가장 마지막에 생성하고 EKS 생성해서 그 안에서 노드 간 통신 등을 테스트해보자.

- 도커로 빌드를 하더라도 Jenkins에서 빌드를 하는 시점에 JPA가 DB랑 연결이 되어야 하니 3306을 열어두는 게 맞겠지?

- CloudWatch를 통해 Control Plane의 로그를 남길 수 있다.

- 우선은 기본적인 구축을 우선으로 하자. 그럴려면 iam 역할이 필요하고 정확히 어떤 역할을 불러오는 코드가 있는지 찾아보자.

## Data 활용

- 이전엔 Data를 크게 활용하지 않았는데 EKS 클러스터에 필요한 정책을 불러오거나 하는 데에 쓰이기 때문에 이번에는 활용해보기로 한다.

- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity

- aws_caller_identity는 내 AWS 계정의 정보를 담은 data이다.

## Auto-Scaler

- EKS 클러스터는 오토 스케일링을 위해 직접 kube-system에 Auto-scaler의 IAM 정책을 적용하고 설치해줘야 한다.

- 이건 Pod Scaler를 의미하는 것이고 노드 그룹의 오토스케일링은 명시만 하면 된다. EC2 오토 스케일링과 동일하다.

## Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```

## YAML

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-apps
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      env: frontend
  template:
    metadata:
      labels:
        env: frontend
    spec:
      containers:
        - name: frontend-apps
          image: nginx:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: dev
spec:
  selector:
    env: frontend
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

- 여기까지가 fargate 테스트

-

## Addon 설치

- 수동으로 설치

```bash
eksctl utils associate-iam-oidc-provider --region=ap-northeast-2 --cluster=EKSCluster --approve
```

```bash
eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster EKSCluster \
    --role-name eks-cluster-example-csi \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve
```

```terraform
  # aws_eks_addon.ebs-csi-driver is tainted, so must be replaced
-/+ resource "aws_eks_addon" "ebs-csi-driver" {
      ~ addon_version               = "v1.28.0-eksbuild.1" -> (known after apply)
      ~ arn                         = "arn:aws:eks:ap-northeast-2:637423467729:addon/EKSCluster/aws-ebs-csi-driver/26c715ae-a089-9ef2-7c1a-f319d31ee5eb" -> (known after apply)
      + configuration_values        = (known after apply)
      ~ created_at                  = "2024-03-11T02:35:15Z" -> (known after apply)
      ~ id                          = "EKSCluster:aws-ebs-csi-driver" -> (known after apply)
      ~ modified_at                 = "2024-03-11T02:36:02Z" -> (known after apply)
      - service_account_role_arn    = "arn:aws:iam::637423467729:role/AmazonEKS_EBS_CSI_DriverRole" -> null
      - tags                        = {} -> null
      ~ tags_all                    = {} -> (known after apply)
        # (3 unchanged attributes hidden)
    }
```

- Addon을 인식해서 보여주는데 role을 만들어서 이 Addon에 입혀줘야 하는 것 같다.

```
tags                      = {
          - "alpha.eksctl.io/cluster-oidc-enabled" = "true" -> null
        }
      ~ tags_all                  = {
          - "alpha.eksctl.io/cluster-oidc-enabled" = "true"
        } -> (known after apply)

```

- 이건 EKS 리소스의 tags 항목인데 이부분이 oidc를 on하는 것 같고 이것 명시 후 Role 만들고 Addon에 Role 적용해서 만들면

- CSI 드라이버 설치까지 자동화 완료 ------ 실패 ㅠ

## Prometheus + Grafana

- 프로메테우스 설치를 위한 준비 CSI 드라이버 뿐만 아니라 스토리지클래스 리소스도 배포 적용해야 한다.

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: prometheus
  namespace: prometheus
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Retain
mountOptions:
  - debug
```

```bash
# add prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# add grafana Helm repo
helm repo add grafana https://grafana.github.io/helm-charts

```

```bash
kubectl create namespace prometheus

helm install prometheus prometheus-community/prometheus \
--namespace prometheus \
--set alertmanager.persistentVolume.storageClass="gp2" \
--set server.persistentVolume.storageClass="gp2"
```

```bash
mkdir ${HOME}/environment/grafana

cat << EoF > ${HOME}/environment/grafana/grafana.yaml
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.prometheus.svc.cluster.local
      access: proxy
      isDefault: true
EoF

```

```bash
kubectl create namespace grafana

helm install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword='EKS!sAWSome' \
    --values ${HOME}/environment/grafana/grafana.yaml \
    --set service.type=LoadBalancer

```

- External-IP로 접속한 다음

- Click '+' button on left panel and select ‘Import’.
  Enter 3119 dashboard id under Grafana.com Dashboard.
  Click ‘Load’.
  Select ‘Prometheus’ as the endpoint under prometheus data sources drop down.
  Click ‘Import’.

## 일단 프론트 Fargate에 배포

```YAML
cat <<EOF > ~/nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-apps
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      env: frontend
  template:
    metadata:
      labels:
        env: frontend
    spec:
      containers:
      - name: frontend-apps
        image: dodo133/ticket4jo-frontend
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: dev
  labels:
    env: dev
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    env: frontend
  type: LoadBalancer
EOF
```

- EKS 모듈을 사용하면 보안 그룹과 IAM Role이 자동으로 생성되어 적용된다.
