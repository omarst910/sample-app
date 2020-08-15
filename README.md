# Setup
This repo has a sample Go web application that displays values from MySQL database on the browser. This is just to demonstrate how the application can be dockerized and deployed to a cluster. This setup is not intended to be optimized for production.

## Prerequistes
To run this example you will need the following installed and configured:

- [Brew](https://brew.sh/) (For macOS only)
- [Docker](https://docs.docker.com/docker-for-mac/install/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-using-other-package-management) This is the kubernetes command line tool.
- [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)

After following the steps in the above links you will have a running minikube cluster on your machine.

## Steps
1. To build and deploy the sample app with its MYSQL database run the following command, this will create 2 pods in your default namespace.
```
make deploy
``` 
2. Find the name of the `mysql` pod by running `kubectl get po` and then run the following command to execute into the container. The password is `password`.
```
kubectl exec -it mysql-66b68bcc9b-l2sjk -- mysql -u root -p
```
3. Copy the content of [this file](.k8s/schema.sql) and then paste it in the terminal where you are executed in the mysql container.

4. Once the SQL command are executed, you will see something like this in your logs 
```
Query OK, 1 row affected (0.01 sec)
```
5. Exit the mysql container by running `\q` and then run the following:
```
make serve
```
6. This will port forward the sample-app to your localhost so you can access it in the browser at `localhost:8080`

7. Go to `localhost:8080/view` and the content of the table will be displayed.

8. To cleanup the stack run:
```
make cleanup
```
# Connection between the dockerfiles and k8s manifests
The dockerfiles are used package your application along with its dependancies. Once its packaged, the docker image is stored locally and can be viewed by running `docker images`. When you are running minikube you can refer to the docker image within the `Deployment` manifests as seen in our [sample-app](.k8s/app/app.yaml) on line 19. 

```
containers:
- name: central
  image: sample-app:latest
  imagePullPolicy: Never
```
By running the steps that were defined in the previous section, the `Makefile` function will build your image using docker and deploy your manifests which would use the image so its all automated.

When you run on a kubernetes cluster you will need to publish your docker image to a Container Registry such as Docker Hub. There are other types of registries as well, each platform providor has their own such as AWS, GCP and Azure. Alternatively, you can host your own registry such as Jfrog artifactory or similar solutions.

This is a [reference](https://docs.docker.com/engine/reference/commandline/push/) to the `docker push` command that publishes the images to your remote registries. 

# High availability of application and failover
As the application are running as a Deployment resource, that allows us to configure the pods to be highly available by increasing the number of replicas. This can be easily done with a deployment through 2 ways:

1. Using Kubectl on the cluster and running `kubectl scale deploy sample-app --replicas=3`

2. By modifying the [sample-app](.k8s/app/app.yaml) manifest and adjusting the `.spec.replicas` from 1 to the required number of replicas.

Having more than 1 replica allows your application to be highly available and minimises/eliminates downtime in case one of the application instances fails.

By default, when a pod fails it will be restarted automatically until its back in a healthy state. 

# Load Balancing
In kubernetes there is a resource type called `Service`. This resource exposes the pod and gives it a fixed IP address that can be internal to the cluster or external depending on the type of service. 

This resource acts like a loadbalancer, as pods die and get rescheduled their IP address would change while the service will maintain its address. When connecting multiple applications with each other, they will need to send their requests to the service of the pod and not to the pod directly.

You can also have multiple replicas of the pod fronted by a single service that will route the traffic to the healthy pods. In that case it acts like an internal load balancer.

To read more about services and its different types, you can refer to this [link](https://kubernetes.io/docs/concepts/services-networking/service/) that has a lot more details.