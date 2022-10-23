resource "aws_s3_bucket" "website" {
  bucket        = local.bucket_name
  tags          = var.tags
  force_destroy = true
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website.json
}

data "aws_iam_policy_document" "website" {
  statement {
    sid = "AllowReadFromAll"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}


resource "aws_s3_bucket_acl" "website" {
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "website_files" {

  for_each = fileset(path.module, "${var.file_path}**")

  content_type = lookup(var.content_type, element(split(".", each.value), length(split(".", each.value)) - 1), "text/html")

  bucket = aws_s3_bucket.website.id

  key = replace(each.value, var.file_path, "")


  source = each.value

  etag = filemd5(each.value)
  tags = {
    description = "static/${replace(each.value, var.file_path, "")}"
  }
}

variable "content_type" {

  type = map(string)

  description = "The file MIME types"

  default = {

    "html" = "text/html"

    "htm" = "text/html"

    "svg" = "image/svg+xml"

    "jpg" = "image/jpeg"

    "jpeg" = "image/jpeg"

    "gif" = "image/gif"

    "png" = "application/pdf"

    "css" = "text/css"

    "js" = "application/javascript"

    "txt" = "text/plain"

  }

}


variable "file_path" {
  type        = string
  description = "The path to the folder of the files you want to upload to S3"
  default     = "static/"
}