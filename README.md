# Deploying an Go application in Kubernetes cluster 

## 1. Prerequisities:

### a. Download and Install Go:
Go to the official Go website (https://golang.org/) and download the appropriate installer for your operating system.
To verify Go Installation run the following command:
```go version```

### b. Download Docker Desktop:
Go to the Docker website (https://www.docker.com/products/docker-desktop) and download the Docker Desktop installer for macOS.
To verify that Docker is installed and running correctly, open a terminal and run the following command:
```docker --version```


## 2. Write HTTP server in Go

Simplest HTTP Server you can write in Go looks like this: 
```go
package main

import (
	"io"
	"net/http"
)

func hello(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Hello world!")
}

func main() {
	http.HandleFunc("/", hello)
	http.ListenAndServe(":8000", nil)
}

```
1. Create `http.go`: 
```go
package server

import (
	"io"
	"net/http"
)

// HTTPServer creates a http server and can be reached through the provided port
type HTTPServer struct {
	port string
}

// NewHTTPServer initializes variables
func NewHTTPServer(port string) *HTTPServer {
	return &HTTPServer{port}
}

// Open creates the http server
func (s HTTPServer) Open() error {
	http.HandleFunc("/", home)
	http.ListenAndServe(s.port, nil)

	return nil
}

func home(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Hello World")
}
```

2. Create `main.go`: 

```go
package main

import (
	"flag"
	"log"

	"github.com/HarshaSiddagangaiah/http-server/pkg/server"
)

func main() {

	port := flag.String("port", "8080", "Port to listen to")
	flag.Parse()

	listeningPort := ":" + *port
	log.Println(listeningPort)

	httpServer := server.NewHTTPServer(listeningPort)

	if err := httpServer.Open(); err != nil {
		log.Fatal("could not open httpServer", err)
	}

}
```
## 4. Dockerize HTTP Server

1. Create go.mod File:
  Open your terminal, navigate to the project directory, and run the following command to create the go.mod file:

  `go mod init github.com/HarshaSiddagangaiah/GO-APP`

2. Create Dockerfile and add below contents:

  ```dockerfile
  # Use the official Golang image as the build stage
  FROM golang:alpine AS build

  # Install git (required for fetching dependencies)
  RUN apk add git

  # Create a working directory inside the container
  RUN mkdir /src
  ADD . /src
  WORKDIR /src

  # Build the Go application inside the container
  RUN go build -o /tmp/http-server ./cmd/http-server/main.go

  # Use a smaller Alpine image as the final stage
  FROM alpine:edge

  # Copy the binary from the build stage to the final image
  COPY --from=build /tmp/http-server /sbin/http-server

  # Set the command to run when the container starts
  CMD /sbin/http-server
  ```

3. Build the Docker Image:

  ```
  docker build -t harshasiddagangaiah/http-server .
  ```
4. Verify the Docker Image:
  ```
  docker run -p 8080:8080 harshasiddagangaiah/http-server
  ```
5. Login and Push to Docker Hub:
  ```
  docker login
  ```
  ```
  docker push harshasiddagangaiah/http-server
  ```

## 6. Setup and Run container on Kubernetes cluster:

Go to the play with kubernetes website (https://labs.play-with-k8s.com/) and login through GitHub.

You can bootstrap a cluster as follows:

 1. Initializes cluster master node:
 ```
 kubeadm init --apiserver-advertise-address $(hostname -i) --pod-network-cidr 10.5.0.0/16
 ```

 2. Initialize cluster networking:
 ```
 kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
 ```
 3. Join worker node to the cluster:
 ```
 kubeadm join 192.168.0.8:6443 --token kxa4bw.t6t1dgkfpwuo5hm3 \
        --discovery-token-ca-cert-hash sha256:1974530eb96d2080a771f81beb6517b686b4065d29a713e276b0e0c2e39c73c7 
 ```
 4. Get information about nodes in the cluster:
 ```
 kubectl get nodes -o wides
 ```
 5. Create a test pod with a specific image:
```
kubectl run testpods --image=harshasiddagangaiah/http-server
```
 6. Expose a test pod as a ClusterIP service:
```
kubectl expose pods/testpod --type=ClusterIP --port=8080 --target-port=8080
```
 7. Get information about pods in the cluster:
```
kubectl get pods
```
 8. Get information about all resources in the cluster:
```
kubectl get all
```
 9. Perform a curl request to the specified IP address:
```
curl http://10.104.155.53
```
 10. Setup yaml file

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: http-server
spec:
  selector:
    matchLabels:
      app: http-server
  template:
    metadata:
      labels:
        app: http-server
    spec:
      containers:
        - name: http-server
          image: harshasiddagangaiah/http-server
          resources:
            limits:
              memory: "128Mi"
              cpu: "500m"
          ports:
            - containerPort: 8080

---
apiVersion: v1
kind: Service
metadata:
  name: http-server
spec:
  selector:
    app: http-server
  ports:
    - port: 8080
      targetPort: 8080

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: http-server
spec:
  backend:
    serviceName: http-server
    servicePort: 8080
  rules:
    - host: http-server.services.harshasiddagangaiah.com
      http:
        paths:
          - backend:
              serviceName: http-server
              servicePort: 8080
```
 11. To run the container on your Kubernetes cluster, Apply the YAML manifest from the specified URL:
```
kubectl apply -f https://github.com/HarshaSiddagangaiah/http-server/stack.yaml
```
Now there should be a pod running the application on your Kubernetes cluster.
