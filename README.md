# Lab 3 — CI/CD with GitHub Actions + Terraform (S3 Static Website)

This repo deploys a static `index.html` site to an S3 **website** bucket using **Terraform**, automatically run by **GitHub Actions** on each push to `main`.

## Quick start

1. **Create a new empty GitHub repo** and push this project.
2. In your repo, add GitHub **Secrets** (Settings → Secrets and variables → Actions → New repository secret):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` = `us-east-1` (or your region)
3. Push to `main`. A workflow will run `terraform init` and `terraform apply`.
4. After it completes,  open the **Actions logs** and copy the `website_endpoint` output.

> ⚠️ Public S3 website access is for lab/testing only. Do **not** use this setup for production.

## Local test  (optional)

```bash
terraform  init
terraform apply -auto-approve
# then: terraform destroy -auto-approve
```

## Clean up

Either let the workflow destroy resources (not included by default), or run locally:

```bash
terraform destroy -auto-approve
```
