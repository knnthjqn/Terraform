output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "app_url_record" {
  value = aws_route53_record.app.fqdn
}

output "media_url_record" {
  value = aws_route53_record.media.fqdn
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.media.domain_name
}

output "media_bucket_name" {
  value = aws_s3_bucket.media.bucket
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "rds_proxy_endpoint" {
  value = aws_db_proxy.main.endpoint
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.app.name
}