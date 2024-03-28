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

### Step 1 - Clone this GitHub repo to your machine

```bash
git clone https://github.com/aws-samples/dr-with-eks-efs.git
cd dr-with-eks-efs

```
### Step 2 - Define the environment variables for the primary region

We will use a few variables during the next steps. Please configure these values with your choice. AWS region codes are listed [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions).

```bash
export PRI_REGION=<Replace with your choice>
export PRI_CFN_NAME=<Replace with your choice>
export PRI_CLUSTER_NAME=<Replace with your choice>

```

### Step 3 - Create CloudFormation stack in the primary region : 

```bash
aws cloudformation create-stack --stack-name $PRI_CFN_NAME --template-body file://config_files/pri_region_cfn.yaml --region $PRI_REGION

```

### Step 4 - Check the status of the CloudFormation stack in the primary region

```bash
watch aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[].StackStatus" --output text --region $PRI_REGION

```

Once the output shows `CREATE_COMPLETE` you can move on to the next step. Exit using `CTRL + C`. 

For easier reference you can navigate to the CloudFormation service console and see which resources are created. If you prefer to use your own values for the parameters in the stack then please use the `--parameters` option with the above command followed by `ParameterKey=KeyPairName, ParameterValue=TestKey`.

### Step 5 - Create the EKS cluster in the primary region

Have a look at the cluster configuration manifest file (`pri_region_cluster.yaml`). We specify Kubernetes version 1.28 and EFS CSI driver as an EKS managed addon.

Set and embed additional variables into manifest file and deploy the cluster to the primary region.

```bash
source config_files/pri_region_env.sh
envsubst < config_files/pri_region_eksctl_template.yaml | eksctl create cluster -f -

```

EKS cluster creation process completes in about 15 minutes. Once it completes update your kubeconfig file to access the cluster by doing `aws eks update-kubeconfig --name $PRI_CLUSTER_NAME --region $PRI_REGION`. 

Verify that the worker nodes status is `Ready` by doing `kubectl get nodes`.

---

> [!NOTE]  
> You can either wait for cluster creation or you can open a separate terminal and move on to deploy the infrastructure in the DR region. If you use a separate terminal then keep in mind that the variables you created in Step 1 and 5 above wont be available in that new terminal. You need to define them again as you will need to have all variables defined in the same terminal when configuring EFS replication at a later step.

---

### Step 6 - Define the environment variables for the DR region

We will use a few variables during the next steps. Please configure the values of your choice below. AWS region codes are listed [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions).

```bash
export DR_REGION=<Replace with your choice>
export DR_CFN_NAME=<Replace with your choice>
export DR_CLUSTER_NAME=<Replace with your choice>

```

### Step 7 - Create CloudFormation stack in the DR region

```bash
aws cloudformation create-stack --stack-name $DR_CFN_NAME --template-body file://config_files/dr_region_cfn.yaml --region $DR_REGION

```

### Step 8 - Check the status of the CloudFormation stack in the DR region

```bash
watch aws cloudformation describe-stacks --stack-name $DR_CFN_NAME --query "Stacks[0].StackStatus" --output text --region $DR_REGION

```

Once the output shows `CREATE_COMPLETE` you can move on to the next step. Exit using `CTRL + C`. 

For easier reference you can navigate to the CloudFormation service console and see which resources are created. If you prefer to use your own values for the parameters in the stack then please use the `--parameters` option with the above command followed by `ParameterKey=KeyPairName, ParameterValue=TestKey`.

### Step 9 - Set and embed additional variables into the eksctl cluster config file for the DR region

Have a look at the cluster configuration manifest file (`dr_region_cluster.yaml`). We specify Kubernetes version 1.28 and EFS CSI driver as an EKS managed addon.

Set and embed additional variables into manifest file and deploy the cluster to the primary region.

```bash
source config_files/dr_region_env.sh
envsubst < config_files/dr_region_eksctl_template.yaml | eksctl create cluster -f -

```

EKS cluster creation process completes in about 15 minutes. Once it completes update your kubeconfig file to access the cluster by doing `aws eks update-kubeconfig --name $DR_CLUSTER_NAME --region $DR_REGION`. 

Verify that the worker nodes status is `Ready` by doing `kubectl get nodes`.

---

> [!NOTE]  
> You can either wait for cluster creation or you can open a separate terminal window and move on to configuring cross region EFS replication. If you use a separate terminal then keep in mind that the variables you created in Step 1, 5 and 9 above wont be available in that new terminal. 

---

### Step 10 - Enable EFS replication

Configure replication from primary to DR region. 

```bash
aws efs update-file-system-protection --file-system-id $DR_EFS_ID --replication-overwrite-protection DISABLED --region $DR_REGION
aws efs create-replication-configuration --source-file-system-id $PRI_EFS_ID --destinations Region=$DR_REGION,FileSystemId=$DR_EFS_ID --region $PRI_REGION

```

You can check the status of the replication by `aws efs describe-replication-configurations --file-system-id $PRI_EFS_ID --region $PRI_REGION`. You can also do `watch aws efs...` as well. It takes ~15 minutes for the initial replication to complete. Once you see the `Status` as `Enabled` you can then move on to the next step. 

---

> [!NOTE]  
> Note that the **file system in the DR region becomes read-only** once the replication status is `Enabled`.

---


### Step 11 - Deploy Kubernetes Storage Class in the EKS cluster of the primary region

Make sure you are in primary cluster kubectl context by using `kubectl config use-context <context-name>` or `kubectx <context-name>`. 

Create a Storage Class resource named as `efs-sc`.

```bash
envsubst < config_files/pri_sc.yaml | kubectl apply -f -

```

Verify that the resource got created successfully. 

```bash
kubectl get storageclass efs-sc

```

### Step 12 - Deploy application in the EKS cluster of the primary region :

Make sure you are in primary cluster kubectl context by using `kubectl config use-context <context-name>` or `kubectx <context-name>`. 

Below command will create a Deployment `efs-app` and a Persistent Volume Claim (PVC) `efs-app-claim` that leverages the Storage Class we created in the previous step. It also exposes the Deployment through an external load balancer, which is an AWS Elastic Load Balancer (ELB) in this case. 

```bash
kubectl apply -f config_files/application.yaml

```

Verify that the resource got created successfully. 

```bash
kubectl get deployment,pvc,svc

```

The container image we use in the Deployment is a simple [Apache Web Server](https://httpd.apache.org/).

---

> [!NOTE]  
> It may take a few minutes for the load balancer to become operational and the targets to be healthy.

---

At this stage you can try to access the web server but it will not be successful because we did not create an index.html in the respective folder, which is `/usr/local/apache2/htdocs/`, that the web server requires. Let' s do that next.

### Step 13 - Create web page content in Amazon EFS

Since the folder `/usr/local/apache2/htdocs/` is using a PVC in the Deployment spec, that PVC is basically consuming Amazon EFS in the background. Hence when we create the index.html it will be available for all the workloads which uses the **same file path** on the EFS thanks to the [subPathPattern](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/README.md#features) feature of the Amazon EFS CSI Driver. 

Let' s randomly pick one of the Pods in the Deployment and get shell access.

```bash
Pod=$(kubectl get pods | grep "efs-app" | awk '{print $1}')
kubectl exec -it $Pod -- sh
```

Create an index.html file in the respective folder with simple content.

```bash
echo "Let's test EFS across regions !" > /usr/local/apache2/htdocs/index.html
exit

```

### Step 14 - Test access to the application

Grab the DNS name of the AWS ELB which exposes the application.

```bash
export APPURL=$(kubectl get svc efs-app-service -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
echo $APPURL

```

In your browser navigate to the DNS name and verify that you can see the page with "Let's test EFS across regions !" .


### Step 15 - Deploy Kubernetes storage class and application in the EKS cluster of the DR region

In this task we will implement steps 11 & 12 & 13 above for the DR region.

```bash
envsubst < config_files/dr_sc.yaml | kubectl apply -f -

```

Verify that the resource got created successfully. 

```bash
kubectl get storageclass efs-sc

```

```bash
kubectl apply -f config_files/application.yaml

```

Verify that the resource got created successfully. 

```bash
kubectl get deployment,pvc,svc

```

Grab the DNS name of the AWS ELB which exposes the application.

```bash
export APPURL=$(kubectl get svc efs-app-service -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
echo $APPURL

```

In your browser navigate to the DNS name and verify that you can see the page with "Let's test EFS across regions !" .

---

> [!NOTE]  
> Thanks to EFS cross-region replication the index.html is already synced to the DR region. Hence you are able to see the same content on the web page.

---

### Step 16 - Test failover to the DR region

In this step we will perform a [failover](https://docs.aws.amazon.com/efs/latest/ug/replication-use-cases.html#replication-fail-over) to the DR region. We first need to delete the replication configuration on the EFS in DR region to make it writable since it has been read-only until now. Deleting a replication configuration and changing the destination file system to be writeable can take several minutes to complete.

Use the following command to delete the replication configuration. Notice that you must use the primary region EFS as source EFS ID.

```bash
aws efs --region $DR_REGION delete-replication-configuration --source-file-system-id $PRI_EFS_ID
```

You can check the status of the by `aws efs describe-replication-configurations --file-system-id $DR_EFS_ID --region $DR_REGION`. You can also do `watch aws efs...` as well. The process takes several minutes to complete. Once the output states `No replications found.` you can move on to the next step.


### Step 17 - Update the web page content and verify access

Make sure you are in the Kubernetes cluster context of the DR region by using `kubectl config use-context <context-name>` or `kubectx <context-name>`.

```bash
Pod=$(kubectl get pods | grep "efs-app" | awk '{print $1}')
kubectl exec -it $Pod -- sh
```

Create an index.html file in the respective folder with simple content.

```bash
echo "We have now successfully failed over to the DR region!" > /usr/local/apache2/htdocs/index.html
exit

```

Grab the DNS name of the AWS ELB which exposes the application.

```bash
export APPURL=$(kubectl get svc efs-app-service -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
echo $APPURL

```

Use your browser in Incognito/InPrivate mode; navigate to the DNS name above and verify that you can see the page with "We have now successfully failed over to the DR region!" . 

### Step 18 - Test failback to the primary region

In this step we will perform a [failback](https://docs.aws.amazon.com/efs/latest/ug/replication-use-cases.html#replication-fail-over) to the primary region. To replicate the changes made to your replica file system (EFS in DR region) during failover, create a replication configuration on the replica file system, where the primary file system (EFS in primary region) is the replication destination.  

```bash
aws efs update-file-system-protection --file-system-id $PRI_EFS_ID --replication-overwrite-protection DISABLED --region $PRI_REGION
aws efs create-replication-configuration --source-file-system-id $DR_EFS_ID --destinations Region=$PRI_REGION,FileSystemId=$PRI_EFS_ID --region $DR_REGION
```

You can check the status of the replication by `aws efs describe-replication-configurations --file-system-id $DR_EFS_ID --region $DR_REGION`. You can also do `watch aws efs...` as well. It takes several minutes for the replication to complete. Once you see the `Status` as `Enabled` you can then move on to the below step.

At this stage you can check the access to the web page in the primary region. Make sure you are in the primary cluster kubectl context by using `kubectl config use-context <context-name>` or `kubectx <context-name>`. Grab the DNS name of the AWS ELB which exposes the application.

```bash
export APPURL=$(kubectl get svc efs-app-service -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
echo $APPURL

```

Use your browser in Incognito/InPrivate mode; navigate to the DNS name above and verify that you can see the page with "We have now successfully failed over to the DR region!" ; since this is the latest content on the web page. 

Currently, the file system in the DR region is writable and the file system in primary region is read-only. We will complete the failover to the primary region by deleting the replication configuration. 

---

> [!NOTE]  
> It is important to understand that once the replication configuration is deleted both file systems become writable. Hence in a real production environment you may want to make sure that the application stack in the DR region does not try to write data. You can achieve this by performing this step in a coordinated fashion.

---

Now use the following command to delete the replication configuration in the DR region. Notice that you must use the DR region EFS as source EFS ID.

```bash
aws efs --region $PRI_REGION delete-replication-configuration --source-file-system-id $DR_EFS_ID
```

You can check the status of the by `aws efs describe-replication-configurations --file-system-id $PRI_EFS_ID --region $PRI_REGION`. You can also do `watch aws efs...` as well. The process takes several minutes to complete. Once the output states `No replications found.` you can move on to the below step.

At this stage the file system in the primary region is writable. Hence we can update the content of the web page. 

Make sure you are in primary cluster kubectl context by using `kubectl config use-context <context-name>` or `kubectx <context-name>`. 

Let' s randomly pick one of the Pods in the Deployment and get shell access.

```bash
Pod=$(kubectl get pods | grep "efs-app" | awk '{print $1}')
kubectl exec -it $Pod -- sh
```

Create an index.html file in the respective folder with simple content.

```bash
echo "We are back on the primary region !" > /usr/local/apache2/htdocs/index.html
exit

```

You can check the access to the web page in the primary region. Make sure you are in the primary cluster kubectl context by using `kubectl config use-context <context-name>` or `kubectx <context-name>`. Grab the DNS name of the AWS ELB which exposes the application.

```bash
export APPURL=$(kubectl get svc efs-app-service -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
echo $APPURL

```

Use your browser in Incognito/InPrivate mode; navigate to the DNS name above and verify that you can see the page with "We are back on the primary region !".

You can now create a replication configuration to start replicating data to the filesystem in the DR region. Just like we did back in step #10 above.

Configure replication from primary to DR region. 

```bash
aws efs update-file-system-protection --file-system-id $DR_EFS_ID --replication-overwrite-protection DISABLED --region $DR_REGION
aws efs create-replication-configuration --source-file-system-id $PRI_EFS_ID --destinations Region=$DR_REGION,FileSystemId=$DR_EFS_ID --region $PRI_REGION

```

You can check the status of the replication by `aws efs describe-replication-configurations --file-system-id $PRI_EFS_ID --region $PRI_REGION`. You can also do `watch aws efs...` as well. It takes several minutes for this process to complete. Once you see the `Status` as `Enabled` you can then move on to the next step.

At this stage the file system in the DR region is read-only. 

Lastly, let' s check the access to the web page in the DR region. 

Make sure you are in the DR cluster kubectl context by using `kubectl config use-context <context-name>` or `kubectx <context-name>`. Grab the DNS name of the AWS ELB which exposes the application.

```bash
export APPURL=$(kubectl get svc efs-app-service -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
echo $APPURL

```

Use your browser in Incognito/InPrivate mode; navigate to the DNS name above and verify that you can see the page with "We are back on the primary region !".


## Clean-up

- Delete the replication configuration

```bash
aws efs --region $PRI_REGION delete-replication-configuration --source-file-system-id $PRI_EFS_ID
```

You can check the status of the by `aws efs describe-replication-configurations --file-system-id $PRI_EFS_ID --region $PRI_REGION`. You can also do `watch aws efs...` as well. The process takes several minutes to complete. Once the output states `No replications found.` you can move on to the below step.

- Delete the application in the DR region. Make sure you are in the DR cluster kubectl context by using `kubectl config use-context <context-name>` or `kubectx <context-name>`.

```bash
kubectl delete -f config_files/application.yaml
kubectl delete storageclass efs-sc

```

- Delete the EKS cluster in the DR region

```bash
envsubst < config_files/dr_region_eksctl_template.yaml | eksctl delete cluster --disable-nodegroup-eviction -f - 
```

- Delete the Cloudformation stack in the DR region

```bash
aws cloudformation delete-stack --stack-name $DR_CFN_NAME --region $DR_REGION
```

Verify the stack deletion using the following command. 

```bash
watch aws cloudformation describe-stacks --stack-name $DR_CFN_NAME --query "Stacks[].StackStatus" --output text --region $DR_REGION

```

Once the output shows `...Stack with id ... does not exist` you can move on to the next step. Exit using `CTRL + C`. 

- Delete the application in the primary region. Make sure you are in the primary cluster kubectl context by using `kubectl config use-context <context-name>` or `kubectx <context-name>`.

```bash
kubectl delete -f config_files/application.yaml
kubectl delete storageclass efs-sc

```

- Delete the EKS cluster in the primary region.

```bash
envsubst < config_files/pri_region_eksctl_template.yaml | eksctl delete cluster --disable-nodegroup-eviction -f - 
```

- Delete the Cloudformation stack in the primary region

```bash
aws cloudformation delete-stack --stack-name $PRI_CFN_NAME --region $PRI_REGION
```

Verify the stack deletion using the following command. 

```bash
watch aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[].StackStatus" --output text --region $PRI_REGION

```

Once the output shows `...Stack with id ... does not exist` you can move on to the next step. Exit using `CTRL + C`. 

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

