```text
ECR Push → EventBridge → Lambda → ECS Update → Slack Notification 🚀
```

---

# ⚡ STEP 1: Create Slack Webhook

---

## 🧭 Go to Slack

👉 Open your Slack workspace
👉 Go to: [https://api.slack.com/apps](https://api.slack.com/apps)

---

## 🧭 Create App

👉 Click **Create New App**
👉 Choose: **From scratch**
👉 App Name: `ECS-Notifier`
👉 Select your workspace

---

## 🧭 Enable Webhook

👉 Go to **Incoming Webhooks**
👉 Turn ON

👉 Click **Add New Webhook to Workspace**
👉 Select channel (ex: `#devops-alerts`)

👉 Copy Webhook URL 👇

```text
https://hooks.slack.com/services/XXXXX/XXXXX/XXXXX
```

---

# ⚙️ STEP 2: Add ENV Variable

Go to:

👉 Lambda → Configuration → Environment variables

Add:

```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXXXX/XXXXX/XXXXX
```

---

# 🧾 STEP 3: UPDATE LAMBDA CODE

Add Slack notification code 👇

```python
import boto3
import os
import json
import urllib3

ecs = boto3.client('ecs')
region = ecs.meta.region_name
http = urllib3.PoolManager()

def lambda_handler(event, context):

    print("🔍 Event:", json.dumps(event))

    if 'detail' not in event:
        return {"message": "Invalid event"}

    cluster = os.environ['ECS_CLUSTER']
    account_id = os.environ['AWS_ACCOUNT_ID']
    webhook_url = os.environ['SLACK_WEBHOOK_URL']

    repository = event['detail'].get('repository-name')
    tag = event['detail'].get('image-tag')

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

    res = ecs.describe_services(cluster=cluster, services=[service])
    task_def_arn = res['services'][0]['taskDefinition']

    task_def = ecs.describe_task_definition(taskDefinition=task_def_arn)
    container_defs = task_def['taskDefinition']['containerDefinitions']

    for c in container_defs:
        if c['name'] == task:
            c['image'] = image_uri

    new_task = ecs.register_task_definition(
        family=task_def['taskDefinition']['family'],
        executionRoleArn=task_def['taskDefinition']['executionRoleArn'],
        networkMode=task_def['taskDefinition']['networkMode'],
        containerDefinitions=container_defs,
        requiresCompatibilities=task_def['taskDefinition']['requiresCompatibilities'],
        cpu=task_def['taskDefinition']['cpu'],
        memory=task_def['taskDefinition']['memory']
    )

    ecs.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=new_task['taskDefinition']['taskDefinitionArn']
    )

    # 🔔 Slack Notification
    message = {
        "text": f"🚀 Deployment Successful!\nService: {service}\nImage: {image_uri}"
    }

    http.request(
        "POST",
        webhook_url,
        body=json.dumps(message),
        headers={"Content-Type": "application/json"}
    )

    return {"message": f"{repository} deployed + Slack notified 🚀"}
```

---

# 🧪 STEP 4: TEST IT

Push image:

```bash
docker push backend:v3
```

---

# 🎉 RESULT

In Slack you will see:

```
🚀 Deployment Successful!
Service: backend-service-i63mwo7e
Image: backend:v3
```

---

# 🔥 README.md SECTION (COPY THIS)

# 🔔 Slack Notification After Deployment

---

# 🧠 What This Does

After ECS deployment:

👉 Lambda sends notification to Slack
👉 You get real-time deployment alerts

---

# ⚙️ Setup

1. Create Slack webhook
2. Add `SLACK_WEBHOOK_URL` in Lambda
3. Update Lambda code

---

# 🚀 Result

Every deployment will send:

```text
🚀 Deployment Successful!
Service: backend-service
Image: backend:v2
```

---

