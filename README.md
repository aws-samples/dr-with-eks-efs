## Multi Region Disaster Recovery (DR) with EKS and EFS for Stateful Workloads

This project shows the steps involved to implement the solution architecture explained in this AWS blog: ....

## Prerequisites

- [ ] A machine which has access to AWS and Kubernetes API server.
- [ ] You need the following tools on the client machine.
	- [ ] [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
   	- [ ] [eksctl](https://eksctl.io/installation/)
  	- [ ] [kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
  	- [ ] [Helm](https://helm.sh/docs/intro/install/)
  	- [ ] [kubectx](https://github.com/ahmetb/kubectx) - Optional
     
Assumption : You already configured a [default] in the AWS CLI config/credentials files.

## Solution

### Step 1 - Clone this GitHub repo to your machine :

```bash
git clone https://github.com/aws-samples/dr-with-eks-efs.git
cd dr-with-eks-efs
```
### Step 2 - Define primary and disaster recovery regions :

Configure your primary and disaster recovery regions as environment variables. AWS region codes are listed [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions). Replace the `AWS-region-code` below with the desired region codes that you choose from the link above.

```bash
export AWS_REGION_PRIMARY=<AWS-region-code>
export AWS_REGION_DR=<AWS-region-code>
```

### Step 3 - Create CloudFormation Stack in the primary region : 

```bash
aws cloudformation create-stack --stack-name primary --template-body file://template/cfn_primary.yaml --region $AWS_REGION_PRIMARY
```

### Step 4 - Check the status of the CloudFormation stack in the primary region :

```bash
watch aws cloudformation describe-stacks --stack-name primary --query "Stacks[0].StackStatus" --output text --region $AWS_REGION_PRIMARY
```

Once the output shows `CREATE_COMPLETE` you can move on to the next step. Exit using `CTRL + C`. 

For easier reference you can navigate to the CloudFormation service console and see which resources are created. 

If you prefer to use your own values for the parameters in the stack then please use the `--parameters` option with the above command followed by `ParameterKey=KeyPairName, ParameterValue=TestKey`.

### Step 5 - Set environment variables :

```bash
source config_files/env_primary.sh
```

### Step 6 - Embed environment variables into the eksctl cluster config file for the primary region :

```bash
envsubst < config_files/cluster_primary_template.yaml > config_files/cluster_primary.yaml
```

Cluster config manifest is configured with Kubernetes v1.28 and the worker nodes use Amazon Linux 2 OS by default. EFS CSI Driver is configured as an EKS managed addon.

### Step 7 - Create the EKS cluster in the primary region : 

```bash
eksctl create cluster -f config_files/cluster_primary.yaml
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

