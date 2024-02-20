## Multi Region Disaster Recovery (DR) with EKS and EFS for Stateful Workloads

This project shows the steps involved to implement the solution architecture explained in this AWS blog: [Multi Region Disaster Recovery with EKS and EFS for Stateful Workloads]().

## Prerequisites

- A local machine which has access to AWS
- Following tools on the machine
	- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
   	- [eksctl](https://eksctl.io/installation/)
  	- [kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
  	- [Helm](https://helm.sh/docs/intro/install/)
  	- [kubectx](https://github.com/ahmetb/kubectx) - Optional
     
Assumption : You already configured a [default] [profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-format-profile) in the AWS CLI.

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

### Step 3 - Create CloudFormation Stack in the primary region : 

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

Have a look at the cluster configuration manifest file (`pri_region_cluster.yaml`). We specify Kubernetes version 1.28 and EFS CSI driver as an EKS managed addon.

### Step 6 - Create the EKS cluster in the primary region : 

```bash
eksctl create cluster -f config_files/pri_region_cluster.yaml
```

EKS cluster creation process completes in about 15 minutes. Once it completes update your kubeconfig file to access the cluster by doing `aws eks update-kubeconfig --name $PRI_CLUSTER_NAME --region $PRI_REGION`. 

Verify that the worker nodes status is `Ready` by doing `kubectl get nodes`.

---

> [!NOTE]  
> You can either wait for cluster creation or you can open a separate terminal and move on to deploy the infrastructure in the DR region. If you use a separate terminal then keep in mind that the variables you created in Step 1 above wont be available in that new terminal. You need to define them again as you will need to have all variables defined in the same terminal when configuring EFS replication at a later step.

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

### Step 10 - Set and embed additional variables into the eksctl cluster config file for the DR region :

```bash
source config_files/dr_region_env.sh
envsubst < config_files/dr_region_eksctl_template.yaml > config_files/dr_region_cluster.yaml
```

Have a look at the cluster configuration manifest file. We specify Kubernetes version 1.28 and EFS CSI driver as an EKS managed addon.

### Step 11 - Create the EKS cluster in the DR region : 

```bash
eksctl create cluster -f config_files/dr_region_cluster.yaml
```

EKS cluster creation process completes in about 15 minutes. Once it completes update your kubeconfig file to access the cluster by doing `aws eks update-kubeconfig --name $DR_CLUSTER_NAME --region $DR_REGION`
Verify that the worker nodes status is `Ready` by doing `kubectl get nodes`.

---

> [!NOTE]  
> You can either wait or you can open a separate terminal window and move on to configuring cross region EFS replication.

---

### Step 12 - Configuring EFS replication :

Enable replication from primary to disaster recovery region. 

```bash
aws efs update-file-system-protection --file-system-id $DR_EFS_ID --replication-overwrite-protection DISABLED --region $DR_REGION
aws efs create-replication-configuration --source-file-system-id $PRI_EFS_ID --destinations Region=$DR_REGION,FileSystemId=$DR_EFS_ID --region $PRI_REGION
```

You can check the status of the replication by `aws efs describe-replication-configurations --file-system-id $PRI_EFS_ID --region $PRI_REGION`. It takes ~15 minutes for the initial replication to be completed. Once you see the `Status` as `Enabled` you can then move on to the next step.

### Step 13 - Deploy Kubernetes storage class in the EKS cluster of the primary region :

Make sure you are in primary cluster kubectl context by using `kubectl config use-context ...` or `kubectx`). 

```bash
envsubst < config_files/pri_sc.yaml | kubectl apply -f -
```

### Step 14 - Deploy application in the EKS cluster of the primary region :



# THINGS TO ADD

- Step 5 & Step 10 replace it `envsubst < test.yaml | eksctl create cluster -f -` OR with the trick mentioned here : https://www.eksworkshop.com/docs/introduction/setup/your-account/using-eksctl/

- The Stack may not be the first one in the stacks list, gotta put a filter in the cloudformation watch query 

- Before deleting the VPCs, we need to delete EFS replication first. Deleting replication takes a bit long (10 min ?)

- https://github.com/eksctl-io/eksctl/issues/6287 , As per our documentation on how to delete clusters here, Pod Disruption Budget policies are preventing the EBS addon from being properly removed. You should run your command with --disable-nodegroup-eviction flag. i.e.

`eksctl delete cluster -f cluster.yaml --disable-nodegroup-eviction`

- When I delete the deployment and PVCs, although the reclaim policy of the PV is set to DELETE by the dynamic provisioning of EFS CSI DRIVER, I see that the folders are still kept in EFS. However all the pods, pvcs and pv s are already deleted in the EKS clusters. This wont be acceptable by any customer. Ok . I needed to set the delete-access-point-root-dir to true in the efs-csi-controller.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

