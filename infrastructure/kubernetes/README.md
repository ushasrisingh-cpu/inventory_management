# Kubernetes deployment

This directory contains a reusable Kustomize base and separate environment overlays for the Spring Boot application.

## Architecture

The request path is:

```text
browser -> internet-facing ALB -> Kubernetes Ingress -> ClusterIP Service:8080 -> Spring Boot pod:8080 -> RDS MySQL:3306
```

The ALB is created later by the AWS Load Balancer Controller. The EKS API endpoint is an administrative interface and remains private by default; it is separate from public application UI access through the ALB.

The base provides the Deployment and ClusterIP Service. The `dev` and `prod` overlays provide separate namespaces, datasource ConfigMaps, image names/tags, and Ingress resources. Database credentials are deliberately not represented as Kubernetes manifests: create the `inventory-database` Secret separately in each cluster/environment.

## Build and push immutable images

Build from the repository root using a commit-derived tag. Replace the placeholders with the AWS account, region, and commit SHA; do not use `latest`.

```text
docker build -t inventory-management:COMMIT_SHA .
aws ecr get-login-password --region AWS_REGION | docker login --username AWS --password-stdin AWS_ACCOUNT_ID.dkr.ecr.AWS_REGION.amazonaws.com
docker tag inventory-management:COMMIT_SHA AWS_ACCOUNT_ID.dkr.ecr.AWS_REGION.amazonaws.com/inventory-management:COMMIT_SHA
docker push AWS_ACCOUNT_ID.dkr.ecr.AWS_REGION.amazonaws.com/inventory-management:COMMIT_SHA
```

Update the overlay `images` block with the actual ECR registry and immutable commit tag before rendering.

## Create database Secrets

Create the Secret out of band in the target cluster. Values must come from a secret manager or secure prompt and must never be committed.

```text
kubectl create secret generic inventory-database -n inventory-dev --from-literal=username="$DEV_DB_USERNAME" --from-literal=password="$DEV_DB_PASSWORD"
kubectl create secret generic inventory-database -n inventory-prod --from-literal=username="$PROD_DB_USERNAME" --from-literal=password="$PROD_DB_PASSWORD"
```

The Secret name and keys must remain `inventory-database`, `username`, and `password`. The database URL is supplied by each overlay ConfigMap and uses the Terraform database name `inventory`.

## AWS Load Balancer Controller

Install the controller separately for each EKS cluster. Do not add the controller Deployment or ServiceAccount to these application manifests. Use the Terraform output `aws_load_balancer_controller_role_arn` for the cluster-specific IRSA role annotation.

```text
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --namespace kube-system --set clusterName=EKS_CLUSTER_NAME --set serviceAccount.create=true --set serviceAccount.name=aws-load-balancer-controller --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=AWS_LOAD_BALANCER_CONTROLLER_ROLE_ARN --set region=AWS_REGION --set vpcId=VPC_ID
```

Use the dev Terraform outputs for the dev cluster and the prod Terraform outputs for the prod cluster. The controller must be installed and its service account annotation verified before applying either application Ingress.

## Replace environment placeholders

Before deployment, replace all of the following in the relevant overlay:

- `AWS_ACCOUNT_ID.dkr.ecr.AWS_REGION.amazonaws.com/inventory-management` with the ECR repository URL
- `DEV_GIT_COMMIT_SHA` or `PROD_GIT_COMMIT_SHA` with an immutable image tag
- `RDS_DEV_ENDPOINT` or `RDS_PROD_ENDPOINT` with the corresponding Terraform RDS endpoint
- `ACM_CERTIFICATE_ARN_PLACEHOLDER` with the approved production ACM certificate ARN
- `inventory.example.invalid` with the approved production DNS name

Production is intentionally HTTPS-only at the application level: its ALB listens on HTTP only for redirect handling and HTTPS for user traffic. Do not apply it while certificate and hostname placeholders remain.

## Render and apply later

Render locally without contacting a cluster:

```text
kubectl kustomize infrastructure/kubernetes/overlays/dev
kubectl kustomize infrastructure/kubernetes/overlays/prod
```

Apply only after image, RDS, Secret, controller, certificate, and hostname values have been reviewed:

```text
kubectl apply -k infrastructure/kubernetes/overlays/dev
kubectl apply -k infrastructure/kubernetes/overlays/prod
```

## Inspect deployments

```text
kubectl get pods -n inventory-dev
kubectl get service -n inventory-dev
kubectl get ingress -n inventory-dev
kubectl logs -n inventory-dev deployment/inventory-management
kubectl get pods -n inventory-prod
kubectl get service -n inventory-prod
kubectl get ingress -n inventory-prod
kubectl logs -n inventory-prod deployment/inventory-management
```

Obtain the ALB address with:

```text
kubectl get ingress inventory-management-dev -n inventory-dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
kubectl get ingress inventory-management-prod -n inventory-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Once the ALB is provisioned and DNS/certificate configuration is ready, Swagger UI is available at `/swagger-ui.html` (or `/swagger-ui/index.html` depending on the Springfox version), for example `https://inventory.example.invalid/swagger-ui.html` in prod. Dev uses the ALB hostname over HTTP until HTTPS is configured.

## Health checks

The application does not currently include Spring Boot Actuator or a dedicated database-independent readiness endpoint. Existing GET routes such as `/api/v1/items` query application data and are not reliable startup probes. No Kubernetes liveness/readiness probes are included until an Actuator health endpoint or dedicated readiness controller is added and reviewed in an application change.