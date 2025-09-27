-   🔹 Why `enable_dns_support` is needed

    -   Redshift clusters are **accessed via DNS endpoints** (e.g. `redshift-cluster-1.abc123xyz.us-east-1.redshift.amazonaws.com`).
    -   If `enable_dns_support = false`, the DNS resolver inside the VPC is disabled → clients (EC2, Lambda, Glue, etc.) **cannot resolve the Redshift cluster’s endpoint** into an IP address.
    -   Without DNS resolution, even if networking and security groups are correct, your cluster is unreachable.

    👉 In short: **DNS support must be enabled so that clients in the VPC can resolve Redshift cluster endpoints.**

-   🔹 Why `enable_dns_hostnames` is needed

    -   If your Redshift cluster is in a **public subnet**, it will be assigned a **public DNS name** that maps to its public IP.
    -   If `enable_dns_hostnames = false`, instances in your VPC **will not get DNS hostnames** and public DNS records won’t work properly.
    -   For Redshift, clients (like BI tools, JDBC/ODBC drivers, or AWS services like QuickSight) always connect using the **DNS endpoint**.
    -   Even in a private-only cluster, AWS still assigns a **private DNS hostname** for the cluster → so enabling hostnames ensures proper endpoint assignment.

    👉 In short: **Hostnames must be enabled so the Redshift cluster and client instances get DNS names that can be resolved.**

---

### `demo-sqls.md` (examples for manual demo)

Create a `demo-sqls.md` with these examples to run against Redshift via `psql` (or Data API / Query Editor):

1. **CONNECT**

    ```sql
    psql -h <endpoint> -p 5439 -U adminuser -d dev
    (you will be prompted for password)
    ```

2. **Create a simple table and INSERT**

    ```sql
    CREATE TABLE public.users (
    id INT,
    name VARCHAR(100),
    email VARCHAR(255)
    );

    INSERT INTO public.users VALUES (1, 'Alice', 'alice@example.com');
    INSERT INTO public.users VALUES (2, 'Bob', 'bob@example.com');

    SELECT * FROM public.users;
    ```

3. **COPY from S3 (inline example)**

    ```sql
    -- Put a CSV file into s3://<staging-bucket>/data/users.csv
    -- The Redshift IAM role must be attached to the cluster (we did this)
    COPY public.users
    FROM 's3://<staging-bucket>/data/users.csv'
    IAM_ROLE '<redshift_role_arn>'
    CSV
    IGNOREHEADER 1;
    ```

4. **UNLOAD to S3**

    ```sql
    UNLOAD ('select * from public.users')
    TO 's3://<staging-bucket>/unload/users_'
    IAM_ROLE '<redshift_role_arn>'
    ALLOWOVERWRITE
    PARALLEL OFF
    CSV;
    ```

5. **Create external schema (Spectrum) using Glue Data Catalog**

    ```sql
    -- You need a Glue catalog database created and tables crawled or defined.
    CREATE EXTERNAL SCHEMA spectrum_schema
    FROM DATA CATALOG
    DATABASE 'my_glue_db'
    IAM_ROLE '<redshift_role_arn>'
    CREATE EXTERNAL DATABASE IF NOT EXISTS;

    -- Then query external tables:
    SELECT * FROM spectrum_schema.some_table LIMIT 10;
    ```

6. **Snapshot & restore (Terraform side / AWS console)**

    - Automated snapshot retention is set via Terraform.
    - Manual snapshots can be taken in console or AWS CLI.

7. **Redshift Parameter Group (example)**

    - We set require_ssl = true in param group; you can query parameters in console.

-   **How to demonstrate features & component mapping**

    -   **Networking & security**: Inspect the created VPC, subnets, route tables, NAT gateway and the Redshift security group. Show that cluster sits in private subnets and port 5439 is only accessible from allowed CIDRs.
    -   **Encryption**: KMS key associated with Redshift; show encryption is enabled.
    -   **IAM role**: Show `aws_iam_role.redshift_role` and the policy allowing S3/Glue/KMS access. Demonstrate COPY/UNLOAD commands using that role.
    -   **COPY / UNLOAD**: Upload CSV to S3 and run COPY into Redshift; then UNLOAD results back to S3.
    -   **Redshift Parameter Group**: `require_ssl` demonstrates setting cluster parameters.
    -   **Subnet group**: `aws_redshift_subnet_group` shows required private subnets.
    -   **Automated snapshots**: Terraform set retention to 7 days. Show snapshot lifecycle in console.
    -   **Spectrum / External schema**: Create a Glue DB & table (not included in full TF here) and demonstrate external schema SQL examples from `demo-sqls.md`.

-   **Additional suggestions / next steps (optional)**

    -   Add `aws_glue_catalog_database` and a `crawler` or `Glue table` resources and then create the external schema automatically (requires adding more IAM permissions).
    -   Use `aws_redshift_snapshot` resource for manual snapshot creation in Terraform (if you want snapshots managed by IaC).
    -   Add `aws_redshift_event_subscription` to get notified of cluster events.
    -   Consider using **Redshift Serverless** for easier demo (resources: `aws_redshift_serverless_namespace`, `aws_redshift_serverless_workgroup`) — I can give Terraform snippets for serverless if you want.
    -   Replace `dc2.large` with `ra3.xlplus` / appropriate instance types when testing performance.

-   **Safety & cleanup**

    -   Because resources cost money, either:

        -   Use the smallest node types and `node_count = 1`, and `skip_final_snapshot = true` (as in the example), or
        -   Run in a short-lived sandbox account and `terraform destroy` to remove everything.
