resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "jenkins-bucket-"
  force_destroy = true


  tags = {
    Name = "jenkins-bucket-20260329034857089900000001"
  }
}

resource "aws_s3_object" "object-txt" {
  bucket = aws_s3_bucket.frontend.id
  key    = "Armageddon-Proof/armageddon-link.txt"
  source = "${path.module}/Armageddon-Proof/armageddon-link.txt"
}

resource "aws_s3_object" "object-jpg" {
  bucket = aws_s3_bucket.frontend.id
  key    = "Armageddon-Proof/arma-proof.jpg"
  source = "${path.module}/Armageddon-Proof/arma-proof.jpg"
}

resource "aws_s3_object" "Jenkins_Proof" {
  for_each = fileset("${path.module}/Jenkins_proof", "**")

  bucket       = aws_s3_bucket.jenkins-bucket-20260329034857089900000001.id
  key          = "Jenkins_Proof/${each.value}"
  source       = "${path.module}/Jenkins_proof/${each.value}"
  content_type = "image/png"
}