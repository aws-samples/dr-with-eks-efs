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
### Step 2 - Define the environment variables for the primary region :

We will use a few variables during the next steps. Please configure the values of your choice below. AWS region codes are listed [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions).

```bash
export PRI_REGION=<Replace>
export PRI_CFN_NAME=<Replace>
export PRI_CLUSTER_NAME=<Replace>
```

### Step 3 - Create CloudFormation Stack in the primary  region : 

```bash
aws cloudformation create-stack --stack-name $PRI_CFN_NAME --template-body file://config_files/pri_region_cfn.yaml --region $PRI_REGION
```

### Step 4 - Check the status of the CloudFormation stack in the primary region :

```bash
watch aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[0].StackStatus" --output text --region $PRI_REGION
```

Once the output shows `CREATE_COMPLETE` you can move on to the next step. Exit using `CTRL + C`. 

For easier reference you can navigate to the CloudFormation service console and see which resources are created. If you prefer to use your own values for the parameters in the stack then please use the `--parameters` option with the above command followed by `ParameterKey=KeyPairName, ParameterValue=TestKey`.

### Step 5 - Set and embed additional variables into the eksctl cluster config file for the primary region :

```bash
source config_files/pri_region_env.sh
envsubst < config_files/pri_region_eksctl_template.yaml > config_files/pri_region_cluster.yaml
```

Have a look at the cluster configuration manifest file. We specify Kubernetes version 1.28 and EFS CSI driver as an EKS managed addon.

### Step 6 - Create the EKS cluster in the primary region : 

```bash
eksctl create cluster -f config_files/pri_region_cluster.yaml
```

EKS cluster creation process completes in about 15 minutes. 

---

> [!NOTE]  
> You can either wait or you can open a separate terminal window and move on to deploy the infrastructure in the DR region.

---

### Step 7 - Define the environment variables for the DR region :

We will use a few variables during the next steps. Please configure the values of your choice below. AWS region codes are listed [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions).

```bash
export DR_REGION=<Replace>
export DR_CFN_NAME=<Replace>
export DR_CLUSTER_NAME=<Replace>
```

### Step 8 - Create CloudFormation Stack in the DR region : 

```bash
aws cloudformation create-stack --stack-name $DR_CFN_NAME --template-body file://config_files/dr_region_cfn.yaml --region $DR_REGION
```

### Step 9 - Check the status of the CloudFormation stack in the DR region :

```bash
watch aws cloudformation describe-stacks --stack-name $DR_CFN_NAME --query "Stacks[0].StackStatus" --output text --region $DR_REGION
```

Once the output shows `CREATE_COMPLETE` you can move on to the next step. Exit using `CTRL + C`. 

For easier reference you can navigate to the CloudFormation service console and see which resources are created. If you prefer to use your own values for the parameters in the stack then please use the `--parameters` option with the above command followed by `ParameterKey=KeyPairName, ParameterValue=TestKey`.

### Step 5 - Set and embed additional variables into the eksctl cluster config file for the DR region :

```bash
source config_files/dr_region_env.sh
envsubst < config_files/dr_region_eksctl_template.yaml > config_files/dr_region_cluster.yaml
```

Have a look at the cluster configuration manifest file. We specify Kubernetes version 1.28 and EFS CSI driver as an EKS managed addon.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

