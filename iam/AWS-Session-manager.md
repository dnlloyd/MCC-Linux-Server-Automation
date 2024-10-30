# AWS Session manager

https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started.html

https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-restrict-access.html

https://docs.aws.amazon.com/systems-manager/latest/userguide/session-preferences-shell-config.html

https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-quickstart.html

## 1. Add to permission set as Inline Policy

**Policy**

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession",
                "ssm:SendCommand"
            ],
            "Resource": [
                "arn:aws:ec2:us-east-1:166865586247:instance/*",
                "arn:aws:ssm:us-east-1:166865586247:document/SSM-SessionManagerRunShell"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetConnectionStatus",
                "ssm:DescribeInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:TerminateSession",
                "ssm:ResumeSession"
            ],
            "Resource": [
                "arn:aws:ssm:*:*:session/${aws:userid}-*"
            ]
        }
    ]
}
```

## 2. Session Manager Prefs

 - Linux shell profile
 ```
 exec /bin/chuser
 ```

 ## 3. instance profile

Policy: AmazonSSMManagedEC2InstanceDefaultPolicy

## 4. VPC endpoints

https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html

