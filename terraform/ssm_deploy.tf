resource "aws_ssm_document" "deploy_app" {
    name = "${var.project_name}-ssm-deploy"
    document_type = "Command"

    content = jsonencode({
        schemaVersion = "2.2"
        description = "Deploy application artifacts from S3 to EC2 instance"
        parameters = {
            ArtifactBucket = {
                type = string
                description = "contains application artifact"
            }
            ArtifactKey = {
                type = string
                description = "contains key of the application artifact"
            }
        }
        mainSteps = [
            {
                action: "aws:runShellScript"
                name = "DeployApplication"
                inputs = {
                    runCommand = [
                        "set -e",
                        "mkdir -p /opt/app",
                        "cd /opt/app",
                        "aws s3 cp s3://{{ ArtifactBucket }}/{{ ArtifactKey}} ./app.zip",
                        "rm -rf current",
                        "mkdir -p current",
                        "unzip -o app.zip -d current",
                        "chmod +x current/scripts/start_app.sh || true",
                        "bash current/scripts/start_app.sh"
                    ]
                }
            }
        ]
    })
}
