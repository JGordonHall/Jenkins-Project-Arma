resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "jenkins-bucket-"
  force_destroy = true


  tags = {
    Name = "jenkins-tf-state-z1"
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

#resource "aws_s3_object" "object-jpg" {
#  bucket = aws_s3_bucket.frontend.id
#  key    = "Jenkins-Proof/Jenkins-Proof.jpg"
#  source = "${path.module}/Jenkins-Proof/Jenkins-Proof.jpg"
#}