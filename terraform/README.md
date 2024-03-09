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
