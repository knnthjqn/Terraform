name: deploy-ec2-app

on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: ap-southeast-1
  PROJECT_NAME: ent-ec2-gha
  ENVIRONMENT: dev

jobs:
  validate:
    name: Validate Terraform
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform fmt check
        working-directory: terraform
        run: terraform fmt -check

      - name: Terraform init without backend
        working-directory: terraform
        run: terraform init -backend=false

      - name: Terraform validate
        working-directory: terraform
        run: terraform validate

  build:
    name: Build Deployment Artifact
    runs-on: ubuntu-latest
    needs: validate

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_GITHUB_ACTIONS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Build artifact metadata
        shell: bash
        run: |
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          ARTIFACT_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-deploy-artifacts-${ACCOUNT_ID}"
          ARTIFACT_NAME="app-${GITHUB_SHA::7}.zip"

          echo "ARTIFACT_BUCKET=${ARTIFACT_BUCKET}" >> $GITHUB_ENV
          echo "ARTIFACT_NAME=${ARTIFACT_NAME}" >> $GITHUB_ENV

      - name: Package application artifact
        shell: bash
        run: |
          mkdir -p build-output
          cp -r app build-output/
          cp -r scripts build-output/
          cd build-output
          zip -r "../${ARTIFACT_NAME}" .
          cd ..

      - name: Upload artifact to S3
        shell: bash
        run: |
          aws s3 cp "${ARTIFACT_NAME}" "s3://${ARTIFACT_BUCKET}/${ARTIFACT_NAME}" --sse aws:kms

  test:
    name: Basic Test
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Check that important files exist
        shell: bash
        run: |
          test -f app/app.py
          test -f scripts/start_app.sh
          echo "Basic test passed"

  deploy:
    name: Deploy to App Fleet
    runs-on: ubuntu-latest
    needs:
      - build
      - test

    steps:
      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_GITHUB_ACTIONS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Build runtime deploy variables
        shell: bash
        run: |
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          ARTIFACT_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-deploy-artifacts-${ACCOUNT_ID}"
          ARTIFACT_NAME="app-${GITHUB_SHA::7}.zip"
          DOCUMENT_NAME="${PROJECT_NAME}-${ENVIRONMENT}-deploy-app"

          echo "ARTIFACT_BUCKET=${ARTIFACT_BUCKET}" >> $GITHUB_ENV
          echo "ARTIFACT_NAME=${ARTIFACT_NAME}" >> $GITHUB_ENV
          echo "DOCUMENT_NAME=${DOCUMENT_NAME}" >> $GITHUB_ENV

      - name: Trigger SSM deployment
        shell: bash
        run: |
          COMMAND_ID=$(aws ssm send-command \
            --document-name "${DOCUMENT_NAME}" \
            --targets "Key=tag:Role,Values=app" \
            --parameters "ArtifactBucket=${ARTIFACT_BUCKET},ArtifactKey=${ARTIFACT_NAME}" \
            --comment "GitHub Actions deploy ${GITHUB_SHA}" \
            --query "Command.CommandId" \
            --output text)

          echo "COMMAND_ID=${COMMAND_ID}" >> $GITHUB_ENV
          echo "${COMMAND_ID}" > command_id.txt

      - name: Upload deployment command id
        uses: actions/upload-artifact@v4
        with:
          name: deploy-command
          path: command_id.txt

  verify:
    name: Verify Deployment
    runs-on: ubuntu-latest
    needs: deploy

    steps:
      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_GITHUB_ACTIONS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Download deployment command id
        uses: actions/download-artifact@v4
        with:
          name: deploy-command

      - name: Inspect SSM command result
        shell: bash
        run: |
          COMMAND_ID=$(cat command_id.txt)
          aws ssm list-command-invocations --command-id "${COMMAND_ID}" --details
