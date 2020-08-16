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
1. To build and deploy the sample app with its MYSQL database run the following command, this will create 2 pods in your default namespace along with the ingress resource: `make deploy`

2. To deploy the app only you can run `make deploy-app`

3. To deploy the DB by itself you can run `make deploy-db`

4. There are 2 options to access the application:
   - Using port-forwarding: To access the application on your browser run `make serve`. This will port forward the sample-app to your localhost so you can access it in the browser at `localhost:8080`
   - Using nginx ingress controller: You will need to grab the Ingress Host name and IP address by running `kubectl get ingress` the result will look something like this:
   
   ```
   NAME              CLASS    HOSTS            ADDRESS        PORTS     AGE
   example-ingress   <none>   sampleapp.info   192.168.64.2   80, 443   34m
   ```
   You will need to modify your `/etc/hosts` next by adding the Address and Host shown above in the file. Navigate to `https://sampleapp.info` to view the page.

5. Go to `localhost:8080/view` or `https://sampleapp.info/view` and the content of the database table will be displayed.

6. To cleanup the stack run: `make cleanup`

## Ingress controller
With minikube Nginx is the default ingress controller. While in a Kubernetes cluster you can use whatever controller you like such as Traefic, Istio or anything else.

If you run `kubectl get po -n kube-system` you will see a nginx pod running. That gets installed automatically when you run `minikube addons enable ingress`. So in the background nginx is doing the routing between your host `sampleapp.info` and your k8s service.

# Creating the Cert secret
Once a real Certificate and Key are provided by the DNS providor, you can create a secret from them that the ingress resource references using the following command. This will create a file called `sample-cert.yaml` which can be renamed to your requirements.

```
kubectl create secret tls sample-app-secret --cert=<CER.CRT> --key=<KEY.PEM> --dry-run -oyaml > sample-cert.yaml
```

The secret name, `sample-app-secret ` in this case is referenced in the [ingress file](.k8s/ingress/example-ingress.yaml) like this:
```
tls:
- hosts:
  - sampleapp.info
  secretName: sample-app-secret
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

# Observability and Monitoring
There are multiple ways for monitoring your applications running within the cluster the simplest one is using the `kubectl` commands. The following 2 commands help with debugging issues with the pods in the cluster:

1. ```kubectl describe pods <POD-NAME>```: This command displays issues with starting the application such as failure to pull the image, missing secrets/config or connectivity issues with upstream dependencies

2. ```kubectl logs <POD-NAME>```: This command will only work if the pod has started and the application ran or is running. It will display the standard output from the application itself which can be helpful in debugging issues.

Other than running the `kubectl` commands there are some tools that help with monitoring and observability. With Minikube you can simply run `minikube dashboard` which will show you a GUI for the cluster and whats running on it including the state of each application. On a cloud platform the Kubernetes cluster would be integrated with managed services that would log all the events and provide monitoring/alerting by default.

## Open source tooling
There are a lot of open source tools that can be installed and configured on the cluster that would give you the required level of logging and monitoring needed. Some of these tools include [Promethues](https://prometheus.io/) for log scraping, [Grafana](https://grafana.com/) for visualisation of the cluster, [Kiali](https://kiali.io/) to visualise how the requests are sent between the pods and [Jaeger](https://www.jaegertracing.io/) that can be used for tracing and troubleshooting microservices-based distributed systems.
