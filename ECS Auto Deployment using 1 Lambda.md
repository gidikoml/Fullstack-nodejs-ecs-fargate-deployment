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

# ⚡ STEP 10: Create EventBridge Rule (Auto Trigger)

#### 🧭 STEP 10.1: Open EventBridge

Go to AWS Console

👉 Search: **EventBridge**
👉 Click **Amazon EventBridge**

#### 🧭 STEP 10.2: Go to Rules

👉 Click **Rules** (left side)
👉 Click **Create rule**

#### 🧭 STEP 10.3: Basic Settings

Fill this:

```text
Rule name: ECR-Auto-Deploy
Description: Trigger Lambda when image pushed to ECR
Event bus: default
```
👉 Click **Next**

#### 🧭 STEP 10.4: Choose Event Source

👉 Select:

```text
Event source: AWS events
AWS service: ECR (Elastic Container Registry)
Event type: ECR Image Action
```

#### 🧭 STEP 10.5: Add Event Pattern (IMPORTANT 🔥)

Choose:

👉 **Custom pattern (JSON)**

Paste this:

```json
{
  "source": ["aws.ecr"],
  "detail-type": ["ECR Image Action"],
  "detail": {
    "action-type": ["PUSH"],
    "result": ["SUCCESS"]
  }
}
```

👉 Click **Next**

#### 🧭 STEP 10.6: Add Target (VERY IMPORTANT)

👉 Target type:

```text
AWS service
```

👉 Select:

```text
Lambda function
```

👉 Choose your Lambda:

```text
AutoUpdateFullstack 
```

👉 Click **Next**

#### 🧭 STEP 10.7: Review & Create

👉 Check everything
👉 Click **Create rule**

---

# 🧪 STEP 11: Testing the Auto Deployment

# 🧒 What are we testing?

We want to check:

👉 When image is pushed to ECR
👉 Lambda triggers automatically
👉 ECS updates automatically


### 🧪 Test 1: Manual Lambda Test (Optional)

This is just to check if Lambda logic is working.

#### 🧭 Step 1: Open Lambda

👉 Go to AWS Console → Lambda
👉 Open your function → `AutoUpdateFullstack`

#### 🧭 Step 2: Configure Test Event

Click **Test → Configure test event**

Paste this:

```json id="9k0z7m"
{
  "source": "aws.ecr",
  "detail-type": "ECR Image Action",
  "detail": {
    "repository-name": "backend",
    "image-tag": "v1"
  }
}
```

👉 Click **Save**
👉 Click **Test**

#### ✅ Expected Output

```text id="phb6zq"
backend updated successfully 🚀
```

---

# ⚠️ Note

👉 This is only a **manual test**
👉 Real system works only when you push image

---

### 🚀 Test 2: Real Auto Deployment (IMPORTANT 🔥)

This is the **actual test**

#### 🧭 Step 1: Build Image

```bash id="4j3p1k"
docker build -t backend ./backend
```

#### 🧭 Step 2: Tag Image

```bash id="3okfhl"
docker tag backend:latest \
YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/backend:v2
```
#### 🧭 Step 3: Push Image

```bash id="4cdv6k"
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/backend:v2
```
#### ⚡ What Happens Automatically

After push:

```text id="p9ch9z"
ECR → EventBridge → Lambda → ECS → New Deployment 🚀
```
#### 👀 Step 4: Verify Lambda

👉 Go to Lambda → Monitor → Logs

You should see:

```text id="9j1wgh"
backend updated successfully 🚀
```
#### 👀 Step 5: Verify ECS

👉 Go to ECS → Cluster → intrepid-panda-grnjfc
👉 Service → backend-service-i63mwo7e
👉 Tasks

You will see:

🔥 Old task → stopping
🔥 New task → running

#### 🧪 Test 3: Frontend Test

Repeat same steps for frontend:

```bash id="0uk6kp"
docker build -t frontend ./client

docker tag frontend:latest \
YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/frontend:v2

docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/frontend:v2
```
#### ✅ Expected Result

👉 Frontend service will update automatically:

```text id="98f7th"
frontend-service-s8nkje7c
```


