# Setup
This repo has a sample Go web application that displays values from MySQL database on the browser. This is just to demonstrate how the application can be dockerized and deployed to a cluster. This setup is not intended to be optimized for production.

## Prerequistes
To run this example you will need a pre-existing Kubernetes cluster or you would need to have minikube pre-installed on your machine. 

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