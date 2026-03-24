# 🚀 Fullstack Auto Deployment (ECR → ECS using 1 Lambda)


# 🧠 Architecture (Very Simple)

```
Developer → Docker Push → ECR → EventBridge → Lambda → ECS → App Updated
```

---

# 📦 Tools Used

* AWS ECR → Store Docker images
* AWS ECS Fargate → Run containers
* AWS Lambda → Brain (automation)
* EventBridge → Trigger Lambda

---

# 🏗️ STEP 1: Create ECR Repositories

Go to AWS Console → ECR → Create Repository

Create 2 repositories:

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

* Name: `intrepid-panda-grnjfc`
* Type: Fargate

Click Create

---

# 📦 STEP 4: Create Task Definitions

---

## 🔹 Backend Task Definition

* Name: `backend`
* Container name: `backend`
* Port: 5000
* Image: backend ECR URL

---

## 🔹 Frontend Task Definition

* Name: `frontend`
* Container name: `frontend`
* Port: 3000
* Image: frontend ECR URL

---

# 🚀 STEP 5: Create ECS Services

Go to:

ECS → Cluster → `intrepid-panda-grnjfc`

---

## 🔹 Backend Service

* Name: `backend-service-i63mwo7e`
* Task: backend
* Desired count: 1

---

## 🔹 Frontend Service

* Name: `frontend-service-s8nkje7c`
* Task: frontend
* Desired count: 1

---

# 🧠 STEP 6: Create Lambda Function

Go to AWS → Lambda → Create Function

* Name: `AutoUpdateFullstack`
* Runtime: Python 3.12

---

# 🧾 STEP 7: Paste Lambda Code

```
import boto3
import os

# ✅ Auto-detect region (no ENV needed)
ecs = boto3.client('ecs')
region = ecs.meta.region_name

def lambda_handler(event, context):

    cluster = os.environ['ECS_CLUSTER']
    account_id = os.environ['AWS_ACCOUNT_ID']

    repository = event['detail']['repository-name']
    tag = event['detail']['image-tag']

    # ✅ Use detected region
    image_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repository}:{tag}"

    service_map = {
        os.environ['BACKEND_REPO']: {
            "service": os.environ['BACKEND_SERVICE'],
            "task": os.environ['BACKEND_TASK']
        },
        os.environ['FRONTEND_REPO']: {
            "service": os.environ['FRONTEND_SERVICE'],
            "task": os.environ['FRONTEND_TASK']
        }
    }

    if repository not in service_map:
        return {"message": f"Unknown repo: {repository}"}

    service = service_map[repository]['service']
    task = service_map[repository]['task']

    # 📦 Get current task definition
    res = ecs.describe_services(cluster=cluster, services=[service])
    task_def_arn = res['services'][0]['taskDefinition']

    task_def = ecs.describe_task_definition(taskDefinition=task_def_arn)
    container_defs = task_def['taskDefinition']['containerDefinitions']

    # 🔄 Update container image
    updated = False
    for c in container_defs:
        if c['name'] == task:
            c['image'] = image_uri
            updated = True

    if not updated:
        raise Exception(f"Container '{task}' not found")

    # 🆕 Register new task definition
    new_task = ecs.register_task_definition(
        family=task_def['taskDefinition']['family'],
        executionRoleArn=task_def['taskDefinition']['executionRoleArn'],
        networkMode=task_def['taskDefinition']['networkMode'],
        containerDefinitions=container_defs,
        requiresCompatibilities=task_def['taskDefinition']['requiresCompatibilities'],
        cpu=task_def['taskDefinition']['cpu'],
        memory=task_def['taskDefinition']['memory']
    )

    # 🚀 Update ECS service
    ecs.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=new_task['taskDefinition']['taskDefinitionArn']
    )

    return {"message": f"{repository} updated successfully 🚀"}
```

---

# ⚙️ STEP 8: Add Environment Variables

Lambda → Configuration → Environment Variables

```
ECS_CLUSTER=intrepid-panda-grnjfc
AWS_ACCOUNT_ID=YOUR_ACCOUNT_ID


BACKEND_REPO=backend
BACKEND_SERVICE=backend-service-i63mwo7e
BACKEND_TASK=backend

FRONTEND_REPO=frontend
FRONTEND_SERVICE=frontend-service-s8nkje7c
FRONTEND_TASK=frontend
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

* Name: `ECRAutoDeploy`

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
docker build -t backend ./backend
docker tag backend:latest backend:v2
docker push ...
```

---

# 🎯 RESULT

🔥 Image pushed
🔥 Lambda triggered
🔥 ECS updated
🔥 New version LIVE

---

# 🎉 DONE!

You built:

✅ Fullstack deployment
✅ Auto CI/CD
✅ Production-level system

---

# 💥 Final Tip

Explain this in interview like this:

👉 "I built an event-driven ECS deployment system using ECR, Lambda, and EventBridge"

🔥 That’s DevOps Engineer level
