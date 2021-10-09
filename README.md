# Deploy Apache Server With Terraform

Basic apache module which creates

- VPC
- Internet gateway
- Route table
- Subnet
- Security group
- Network Interface

All of these resources are created and linked together by default. The default variables are all customizable using the **terraform.tfvar** file.

To deploy these resources on your aws account add the access key and secret key to the **terraform.tfvars** file.

```hcl
access_key_var = ""
secret_key_var = ""
```

To run this files you will need terraform to be installed version ^1.0.0 and run the following commands.

```
C:\file\path> terraform init

C:\file\path> terraform apply
```
