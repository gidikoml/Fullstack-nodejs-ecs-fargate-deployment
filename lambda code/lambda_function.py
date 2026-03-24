import boto3
import os
import json

ecs = boto3.client('ecs')
region = ecs.meta.region_name

def lambda_handler(event, context):

    print("🔍 Full Event Received:", json.dumps(event))

    # ✅ Validate event structure
    if 'detail' not in event:
        return {"message": "Invalid event: No 'detail' found"}

    cluster = os.environ['ECS_CLUSTER']
    account_id = os.environ['AWS_ACCOUNT_ID']

    repository = event['detail'].get('repository-name')
    tag = event['detail'].get('image-tag')

    if not repository or not tag:
        return {"message": "Missing repository-name or image-tag"}

    image_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repository}:{tag}"

    print(f"📦 New Image URI: {image_uri}")

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

    # ❌ Unknown repo safety
    if repository not in service_map:
        return {"message": f"Unknown repo: {repository}"}

    service = service_map[repository]['service']
    task = service_map[repository]['task']

    print(f"🚀 Updating Service: {service}, Container: {task}")

    # 📦 Get current task definition
    res = ecs.describe_services(cluster=cluster, services=[service])
    task_def_arn = res['services'][0]['taskDefinition']

    task_def = ecs.describe_task_definition(taskDefinition=task_def_arn)
    container_defs = task_def['taskDefinition']['containerDefinitions']

    # 🔄 Update container image
    updated = False
    for c in container_defs:
        if c['name'] == task:
            print(f"🔄 Updating container {task} image")
            c['image'] = image_uri
            updated = True

    if not updated:
        raise Exception(f"❌ Container '{task}' not found")

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

    print("🆕 New task definition registered")

    # 🚀 Update ECS service
    ecs.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=new_task['taskDefinition']['taskDefinitionArn']
    )

    print("✅ ECS service updated successfully")

    return {"message": f"{repository} updated successfully 🚀"}
