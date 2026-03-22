# GitHub Actions Secrets And Variables Setup

This project uses GitHub Actions for:

- Frontend Docker build and push to Amazon ECR
- Backend Docker build and push to Amazon ECR
- Manual Terraform deploy and destroy for:
  - VPC
  - RDS
  - ECS Task

Before running the workflows, add the required GitHub repository secrets and variables.

## Open GitHub Settings

In your GitHub repository:

1. Go to `Settings`
2. Open `Secrets and variables`
3. Click `Actions`

You will see:

- `Secrets`
- `Variables`

## Add Repository Secrets

Add these under `Secrets`:

### `AWS_ACCESS_KEY_ID`

Your AWS access key ID for the IAM user or role used by GitHub Actions.

### `AWS_SECRET_ACCESS_KEY`

Your AWS secret access key for the IAM user or role used by GitHub Actions.

## Summary Table

### Secrets

| Name | Required | Purpose |
|------|----------|---------|
| `AWS_ACCESS_KEY_ID` | Yes | AWS authentication |
| `AWS_SECRET_ACCESS_KEY` | Yes | AWS authentication |

## Add Repository Variables

Add these under `Variables`:

### `AWS_REGION`

Example:

```text
us-east-1
```

This is the AWS region used by:

- ECR workflows
- Terraform workflows

### `TF_STATE_BUCKET`

This is the S3 bucket name used for Terraform remote state.

Example:

```text
my-terraform-state-bucket
```

All manual Terraform workflows use this bucket to store Terraform state.

### `TF_LOCK_TABLE`

This is the DynamoDB table name used for Terraform state locking.

Example:

```text
terraform-lock-table
```

Create the DynamoDB table like this:

1. Open AWS Console.
2. Search for `DynamoDB`.
3. Click `Create table`.
4. Table name:
   `terraform-lock-table`
   You can choose another name, but use the same name in GitHub `TF_LOCK_TABLE`.
5. Partition key:
   `LockID`
6. Type:
   `String`
7. Keep default settings.
8. Click `Create table`.

All manual Terraform workflows use this table to lock state during apply and destroy.

### Variables

| Name | Required | Purpose |
|------|----------|---------|
| `AWS_REGION` | Yes | AWS region |
| `TF_STATE_BUCKET` | Yes | Terraform remote state S3 bucket |
| `TF_LOCK_TABLE` | Yes | Terraform state locking DynamoDB table |

## Why `TF_STATE_BUCKET` And `TF_LOCK_TABLE` Matter

Without remote Terraform state:

- `terraform apply` may recreate resources
- `terraform destroy` may not delete existing resources
- GitHub Actions runners do not remember previous Terraform state

Using:

- `TF_STATE_BUCKET`
- `TF_LOCK_TABLE`

makes Terraform remember what was created across GitHub Actions runs.

## Workflows That Use These Values

### Docker And ECR Workflows

Use:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### Terraform Workflows

Use:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `TF_STATE_BUCKET`
- `TF_LOCK_TABLE`

## Manual Terraform Workflows

These workflows are manual-only:

- `.github/workflows/vpc-terraform-deploy.yml`
- `.github/workflows/rds-terraform-deploy.yml`
- `.github/workflows/ecs-task-terraform-deploy.yml`

They support:

- `plan`
- `apply`
- `destroy`

## Recommended IAM Permissions

The AWS identity used by GitHub Actions should have permission for:

- Amazon ECR
- ECS
- VPC
- RDS
- S3
- DynamoDB
- IAM if Terraform creates or uses IAM resources

## Final Checklist

Before running workflows, make sure you added:

### Secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Variables

- `AWS_REGION`
- `TF_STATE_BUCKET`
- `TF_LOCK_TABLE`
