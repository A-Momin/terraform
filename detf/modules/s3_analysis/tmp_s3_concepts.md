Explain following concepts in context of AWS S3:

    -   aws_s3_bucket_public_access_block
    -   aws_s3_bucket_ownership_controls
    -   aws_s3_bucket_logging
    -   aws_s3_bucket_inventory
    -   example
    -   aws_s3_bucket_analytics_configuration
    -   aws_s3_access_point

---

## 1. **`aws_s3_bucket_public_access_block`**

-   Controls **public access settings** for an S3 bucket.
-   Prevents accidental public exposure of data by blocking things like:

    -   Public ACLs (Access Control Lists)
    -   Public bucket policies
    -   Cross-account ACLs

👉 Example use case:
You want to make sure **no one accidentally makes your bucket public**, even if they try to add a public ACL.

```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}
```

---

## 2. **`aws_s3_bucket_ownership_controls`**

-   Controls **object ownership** in the bucket.
-   Determines who owns objects uploaded by other accounts.
-   Important when multiple AWS accounts or services upload to the same bucket.

👉 Example use case:
You want the **bucket owner** (your account) to own all uploaded objects, regardless of who uploads.

```hcl
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
```

---

## 3. **`aws_s3_bucket_logging`**

-   Enables **server access logging** for the bucket.
-   Logs are stored in another S3 bucket, showing:

    -   Who accessed the bucket
    -   What operations they performed
    -   When requests happened

👉 Example use case:
Compliance/audit logging — track every access request.

```hcl
resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}
```

---

## 4. **`aws_s3_bucket_inventory`**

-   Configures **inventory reports** for objects in a bucket.
-   Periodically generates a report (CSV/ORC/Parquet) that lists:

    -   Object names, sizes, encryption status, replication status, etc.

-   Useful for audits, cost analysis, or compliance checks.

👉 Example use case:
Generate a weekly report of **all objects and their encryption status**.

```hcl
resource "aws_s3_bucket_inventory" "example" {
  bucket = aws_s3_bucket.my_bucket.id
  name   = "inventory-report"

  destination {
    bucket {
      bucket_arn = aws_s3_bucket.inventory_dest.arn
      format     = "CSV"
    }
  }

  included_object_versions = "All"
  schedule {
    frequency = "Weekly"
  }
}
```

---

## 5. **`aws_s3_bucket_analytics_configuration`**

-   Provides **storage class analysis**.
-   Monitors access patterns for objects in a bucket and helps decide when to transition data to cheaper storage (e.g., S3 Standard → S3 Glacier).

👉 Example use case:
Analyze objects in the bucket to see if infrequently accessed data should be moved to **S3 IA (Infrequent Access)**.

```hcl
resource "aws_s3_bucket_analytics_configuration" "example" {
  bucket = aws_s3_bucket.my_bucket.id
  name   = "analytics-config"

  storage_class_analysis {
    data_export {
      destination {
        s3_bucket_destination {
          bucket_arn = aws_s3_bucket.analytics_reports.arn
          format     = "CSV"
        }
      }
    }
  }
}
```

---

## 6. **`aws_s3_access_point`**

-   An **alternate entry point** to an S3 bucket.
-   Lets you control **access policies** independently of the bucket policy.
-   Great for **multi-tenant environments** where you want different apps/teams to have isolated access to the same bucket.

👉 Example use case:
Instead of giving direct bucket access, create access points for each app with scoped policies.

```hcl
resource "aws_s3_access_point" "example" {
  bucket = aws_s3_bucket.my_bucket.id
  name   = "app1-access"

  vpc_configuration {
    vpc_id = aws_vpc.main.id
  }
}
```

---

## ✅ Summary Table

| Terraform Resource                        | Purpose                                              |
| ----------------------------------------- | ---------------------------------------------------- |
| **aws_s3_bucket_public_access_block**     | Prevents accidental public access (ACLs & policies)  |
| **aws_s3_bucket_ownership_controls**      | Decides object ownership (uploader vs bucket owner)  |
| **aws_s3_bucket_logging**                 | Enables access logs for compliance/audit             |
| **aws_s3_bucket_inventory**               | Generates inventory reports of objects               |
| **aws_s3_bucket_analytics_configuration** | Analyzes access patterns to optimize storage classes |
| **aws_s3_access_point**                   | Creates scoped access endpoints to buckets           |
