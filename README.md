# Argo CD

- Argo CD를 사용한 쿠버네티스 클러스터 CI/CD

- Jenkins + Argo CD

## AWS EKS

- 프라이빗 서브넷에 EKS 클러스터를 구성하는 것 부터 시작한다.

- Fargate로 EKS 클러스터 구성하고 인그레스 설정하고 Argo CD

- 마스터 노드에 kubectl 설치

```bash
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.9/2024-01-04/bin/linux/amd64/kubectl

chmod +x ./kubectl

mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
```

- eksctl 설치

```bash
#!/bin/bash

# for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

# (Optional) Verify checksum
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz

sudo mv /tmp/eksctl /usr/local/bin
```

- 논리는 모든 쿠버네티스 서비스가 동일한 것 같다. 클러스터를 생성하고 그 클러스터의 권한을 마스터 노드의 kubectl이 얻는다.

- 구체적으로 AWS EKS의 방식은 `eksctl로 클러스터를 생성하고` `aws eks` 명령어로 kubeconfig에 연결을 한다?

- `aws ec2 describe-vpcs`로 vpc의 id를 찾는다.

- `aws ec2 describe-subnets --filter 'Name=vpc-id,Values=vpc-0d554d0e260bb934e'`로 서브넷의 ID를 찾는다.

- `aws ec2 describe-subnets --filter 'Name=vpc-id,Values=vpc-0d554d0e260bb934e' | jq '.Subnets[].SubnetId'` 서브넷 ID만 필터링

- `jq`는 JSON 포맷 데이터에서 원하는 데이터를 추출하는 명령어

- `subnet-01c3c19fecbffaf2b`b `subnet-087765e27d17ef7cf`a

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: EKSCluster
  region: ap-northeast-2
  version: "1.27"

iam:
  withOIDC: true

vpc:
  subnets:
    private:
      ap-northeast-2a: { id: subnet-087765e27d17ef7cf }
      ap-northeast-2b: { id: subnet-01c3c19fecbffaf2b }
```

- 위는 일단 생성만 테스트

- `aws eks update-kubeconfig --region ap-northeast-2 --name EKSCluster`로 kubectl이 EKS 클러스터를 제어할 수 있도록 한다.

- **_아래는 클러스터 구성 yaml 예시인데 스팟인스턴스나 여러가지 내용이 있음 참고해볼만 한 듯_**

- https://repost.aws/knowledge-center/eks-multiple-node-groups-eksctl

- **_클러스터 구성 관련 yaml 파일의 Schema_**

- https://eksctl.io/usage/schema/

### 조금 두서 없이 할 것 정리 2/27 16:47

- fargate로 클러스터를 생성할 것인데 fargate에 적용하는 AWS 정책 (AmazonEKSWorkerNodePolicy,
  AmazonEC2ContainerRegistryReadOnly)와 같은 정책들 찾아야함

- https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/eks-add-ons.html

- Addon의 목록

- https://eksctl.io/usage/iam-policies/

- eksctl yaml 파일에서 노드 그룹에 IAM 정책 attach

- cni Addon은 기본값이 아니며 정책을 필요로 한다.

- coreDNS, kube-proxy, aws-node는 기본 Addon인 듯 하다.

- 근데 이부분이 yaml로 생성해도 적용이 되는 지는 확인이 안된다. 이전에 kube-system 조회했을 때 coreDNS 외 다른 Addon들은 확인이 안되었기 때문

- **_fargate 적용 방법_**

- fargateProfiles를 명시하는데 selectors 옵션에 namespace를 명시한다.

- 그럼 그 namespace에 해당하는 파드들은 모두 Fargate에서 실행된다.

- 일반 EC2로 생성되는 NodeGroup도 생성한다.

- Fargate로 생성될 namespace를 가진 pod들도 클러스터에서 정한 pod cidr, 클러스터가 생성된 서브넷의 ip 대역을 가진다.

- 그럼 지금 결정해야 할 것은 프론트엔드 단을 Fargate로 생성할 것인데 프론트엔드/백엔드를 namespace를 나눠서 다르게 할 것인지 같은 namespace 내에서 label에 따라 나눌 것인지를 알아보고 결정해야 한다.

- 시간이 오래 걸리더라도 일단 클러스터 생성하고 배포 yaml 파일 작성해서 label에서 다르게 생성한 pod가 fargate랑 일반 노드로 나뉘는지 확인하고 가능하면 서로 통신도 가능한지 확인한다.

- node에 대한 ssh는 그냥 allow를 하면 마스터노드에서 id_rsa 키가 생성되고 그 키로 접근하는 듯 하다.

- labels -> env를 fargate에 해당하는 것으로 주면 된다.

- fargate 사용에 유의할 점은 로드 밸런서의 대상이 될 때 IP를 통해서만 가능하다.

- 프론트엔드 단의 service를 배포할 때

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysvc
  namespace: dev
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external" #외부
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip" #ip대상 --> fargate 조건
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing" #외부
spec:
  selector:
    app: myfg
  ports:
    - port: 80
      targetPort: 8080
  type: LoadBalancer
```

- 와 같이 어노테이션을 명시해야 한다.

- 위 어노테이션을 사용하기 위해서는

- `curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json`

- 정책 json 파일을 다운로드 받고

```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```

- 정책을 생성한 다음

```bash
eksctl create iamserviceaccount \
  --cluster=EKSCluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::111122223333:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

- 로 로드밸런서 컨트롤러를 설치해서 실행시킨다.

- https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html

- 로드밸런서 컨트롤러 관련 문서

- https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/calico.html

- Calico CNI 정책 관련 문서

- EKS + Fargate의 경우 Calico가 지원되지 않는다. Calico 없이 Fargate 파드와 일반 Node의 파드가 통신이 가능한지 확인이 우선인 것 같다.

- nodeGroups vs managedNodeGroups - managed는 인스턴스 타입만 명시하고 AMI는 선택하지 않는다.

- 우선 생성은 완료했고 fargate랑 일반 노드로 나눠지는지 노드 하나 삭제했을때 desired capacity 유지 되는지 그리고 fargate <-> EC2Node 사이에 통신이 가능한지 확인하면 1차적으로 클러스터 구성은 끝난다.

- 그리고 어차피 한 리전 내가 맡기로 했으니 RDS도 준비하고 Terraform도 사용하기로 했으니 Terraform으로 다시 준비하자

- Addon을 yaml파일에 명시하기 - 큰 iam: 항목에서 serviceAccounts에 사용할 addon과 그 addon이 실행될 namespace를 명시하고 그 addon이 필요한 정책이 있다면 그 정책의 이름을 명시한다.

- 그리고 그 addon의 영향을 받을 노드 그룹의 iam 항목에도 withAddonPolicies에 다시한번 명시한다.

- 그런데 위 iam 항목과 아래 iam 항목에서 정책 이름의 표현이 서로 다른 것 같다.

- `eksctl get iamserviceaccount --cluster [클러스터명]`

- 클러스터 내 모든 서비스어카운트를 조회, addon에 적용된 모든 정책을 조회하는 것과 동일하다고 볼 수 있다.

- 일단 테라폼으로 구축이 먼저가 되었으니 그것부터 하자.

## ArgoCD

- ArgoCD 설치

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
```

- Argo CLI 설치

```bash
sudo curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.7/argocd-linux-amd64

sudo chmod +x /usr/local/bin/argocd

```

- ArgoCD 서버 서비스 로드밸런서로 변경

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

```bash
export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`

export ARGO_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure

```

C:.
└─terraform
│ .gitignore
│ eks-iam.tf
│ eks.tf
│ instance.tf
│ key.tf
│ provider.tf
│ security-group.tf
│ variable.tf
│ vpc.tf
│
├─.terraform
│ └─modules
│ │
│ └─vpc
│
└─script
jenkins.sh
