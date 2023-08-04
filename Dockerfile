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