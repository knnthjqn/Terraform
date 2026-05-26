name = deploy-ec2-app

on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: us-east-1
  PROJECT_NAME: test-stack
  ENVIRONEMNT: dev

jobs:
  validate:
    name: validate terraform
    runs-on: ubuntu-latest

    steps:
      - name: check repo
        uses: actions/checkout@v4

      - name: setup terraform
        uses: hashicorp/setup-terraform@v3

      - name: format check
        working-directory: terraform
        run: terraform fmt -check

      - name: backend init
        working-directory: terraform
        run: terraform init -backend=false

      - name: terraform validate
        working-directory: terraform
        run: terraform validate

  build:
    name: build artifact
    runs-on: ubuntu-latest

    steps:
      - name: check repo
        uses: actions/checkout@v4
