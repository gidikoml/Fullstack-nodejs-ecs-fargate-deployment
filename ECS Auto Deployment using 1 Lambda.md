
# 🚀 Fullstack ECS Auto Deployment using 1 Lambda (ECR → ECS)


# 🧠 Architecture (Simple)

```
Developer → Docker Push → ECR → EventBridge → Lambda → ECS → App Updated
```

---

# 📦 Tools We Use

* AWS ECR (store images)
* AWS ECS Fargate (run containers)
* AWS Lambda (automation brain)
* EventBridge (trigger system)

---

# 🏗️ STEP 1: Create ECR Repositories

Go to AWS Console → ECR → Create Repository

Create 2 repos:

👉 backend
👉 frontend

---

# 🐳 STEP 2: Build & Push Docker Images

Open terminal:

```
AWS_ACCOUNT_ID=YOUR_ID
AWS_REGION=us-east-1
```

---

## 🔹 Backend

```
docker build -t backend ./backend

docker tag backend:latest \
$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend:v1

aws ecr get-login-password --region $AWS_REGION | \
docker login --username AWS --password-stdin \
$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend:v1
```

---

## 🔹 Frontend

```
docker build -t frontend ./client

docker tag frontend:latest \
$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend:v1

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend:v1
```

---

# 🏗️ STEP 3: Create ECS Cluster

Go to ECS → Clusters → Create

* Name: production-fullstack-cluster
* Type: Fargate

Click Create

---

# 📦 STEP 4: Create Task Definitions

---

## 🔹 Backend Task

* Name: backend
* Image: backend repo URL
* Port: 5000

---

## 🔹 Frontend Task

* Name: frontend
* Image: frontend repo URL
* Port: 3000

---

# 🚀 STEP 5: Create ECS Services

Go to Cluster → Create Service

---

## Backend Service

* Name: backend-service
* Task: backend
* Tasks: 1

---

## Frontend Service

* Name: frontend-service
* Task: frontend
* Tasks: 1

---

# 🧠 STEP 6: Create Lambda Function (ONE ONLY)

Go to AWS → Lambda → Create

* Name: AutoUpdateFullstack
* Runtime: Python 3.12

---

# 🧾 STEP 7: Paste Lambda Code

```
import boto3
import os

ecs = boto3.client('ecs')

def lambda_handler(event, context):

    cluster = os.environ['ECS_CLUSTER']
    account_id = os.environ['AWS_ACCOUNT_ID']
    region = os.environ['AWS_REGION']

    repository = event['detail']['repository-name']
    tag = event['detail']['image-tag']

    image_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repository}:{tag}"

    # Decide service based on repo
    if repository == "backend":
        service = "backend-service"
        container = "backend"

    elif repository == "frontend":
        service = "frontend-service"
        container = "frontend"

    else:
        return {"message": "Unknown repo"}

    # Get current task definition
    res = ecs.describe_services(cluster=cluster, services=[service])
    task_def_arn = res['services'][0]['taskDefinition']

    task_def = ecs.describe_task_definition(taskDefinition=task_def_arn)
    container_defs = task_def['taskDefinition']['containerDefinitions']

    # Update image
    for c in container_defs:
        if c['name'] == container:
            c['image'] = image_uri

    # Register new task
    new_task = ecs.register_task_definition(
        family=task_def['taskDefinition']['family'],
        executionRoleArn=task_def['taskDefinition']['executionRoleArn'],
        networkMode=task_def['taskDefinition']['networkMode'],
        containerDefinitions=container_defs,
        requiresCompatibilities=task_def['taskDefinition']['requiresCompatibilities'],
        cpu=task_def['taskDefinition']['cpu'],
        memory=task_def['taskDefinition']['memory']
    )

    # Update service
    ecs.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=new_task['taskDefinition']['taskDefinitionArn']
    )

    return {"message": f"{repository} updated"}
```

---

# ⚙️ STEP 8: Add Environment Variables

Lambda → Configuration → Environment Variables

```
ECS_CLUSTER = production-fullstack-cluster
AWS_ACCOUNT_ID = YOUR_ID
AWS_REGION = us-east-1
```

---

# 🔐 STEP 9: Add IAM Role

Attach this policy:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Resource": "*"
    }
  ]
}
```

---

# ⚡ STEP 10: Create EventBridge Rule

Go to EventBridge → Create Rule

* Name: ECRAutoDeploy

Pattern:

```
{
  "source": ["aws.ecr"],
  "detail-type": ["ECR Image Action"],
  "detail": {
    "action-type": ["PUSH"],
    "result": ["SUCCESS"]
  }
}
```

Target:

👉 Lambda → AutoUpdateFullstack

---

# 🧪 STEP 11: TEST IT

Push new image:

```
docker tag backend:latest backend:v2
docker push ...
```

---
