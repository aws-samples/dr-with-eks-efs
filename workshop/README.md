# Workshop Content

This folder contains the manifests and scripts used in the Building Modern Resilient Applications using Amazon EKS and Amazon EFS Workshop.

Please use the following commands first in Cloudshell.

```
git clone https://github.com/aws-samples/dr-with-eks-efs.git
cd dr-with-eks-efs/
chmod +x workshop/startup.sh

./workshop/startup.sh

source ~/.bashrc
```

## Optional

You will need to switch between contexts in kubectl at later stages of the workshop. To make that process easier you can rename the contexts in the kubectl config file by following the below commands. 

```
kubectx
```

Output 
```
arn:aws:eks:us-east-1:<AWS_ACCOUNT_ID>:<context_name_for_primary_cluster>
arn:aws:eks:us-west-2:<AWS_ACCOUNT_ID>:<context_name_for_dr_cluster>
```

Rename the primary cluster context.

```
kubectx pri=arn:aws:eks:us-east-1:<AWS_ACCOUNT_ID>:<context_name_for_primary_cluster>
```

Output
```
Context "arn:aws:eks:us-east-1:<AWS_ACCOUNT_ID>:<context_name_for_primary_cluster>" renamed to "pri".
```

Rename the DR cluster context

```
kubectx sec=arn:aws:eks:us-west-2:<AWS_ACCOUNT_ID>:<context_name_for_dr_cluster>
```

Output
```
Context "arn:aws:eks:us-west-2:<AWS_ACCOUNT_ID>:<context_name_for_dr_cluster>" renamed to "dr".
```

