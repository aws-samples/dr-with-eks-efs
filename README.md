## Multi Region Disaster Recovery with EKS and EFS for Stateful Workloads

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

### Step 1 - Clone this GitHub repo to your machine:

```bash
git clone https://github.com/aws-samples/dr-with-eks-efs.git
cd dr-with-eks-efs
```

### Step 2 - Create CloudFormation Stack for the primary region : 

```bash
aws cloudformation create-stack --stack-name primary --template-body file://template/cfn_primary.yaml
```

### Step 3 - Check the status of the CloudFormation stack :

```bash
watch aws cloudformation describe-stacks --stack-name primary --query "Stacks[0].StackStatus" --output text
```

Once the output shows `CREATE_COMPLETE` you can move on to the next step. Exit using `CTRL + C`. 

For easier reference you can navigate to the CloudFormation service console and see which resources are created. At a high level the resources created are a VPC, two public subnets, two private subnets.

If you prefer to use your own values for the parameters in the stack then please use the `--parameters` option with the above command followed by `ParameterKey=KeyPairName, ParameterValue=TestKey`.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

