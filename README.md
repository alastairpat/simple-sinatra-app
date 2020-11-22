# Simple Sinatra App

## Build/Deployment Automation

### Build

Every commit to master and pull-request to master will be run past 
[cfn-lint](https://github.com/aws-cloudformation/cfn-python-lint) and also be
`docker built` by GitHub actions.

### Deployment

To deploy to production, create a new release, and it will be built and deployed.

## Rationale for Solution

First and foremost, I am a big fan of Docker. I think it solves many problems
that developers and operations people have previously struggled with. While 
customised EC2 instances are a huge improvement on the 'pets' people in IT
have historically relied on, being able to run the exact same runtime on
the server as the developer machine is a huge leap forward in my opinion.

Prior to this challenge, I had not used AWS' ECS solution (my background is
mostly on-premise Kubernetes), but was interested to try out ECS Fargate as it
is highly cost-effective (and, if you haven't already noticed my preference for
`us-east-1`, I am clearly a cheapskate.) I was pleasantly surprised by how easy
it was to provision workloads without managing any underlying infrastructure.

## Requirements for Running

This solution assumes that you have an AWS account available, and that whatever
VPC and subnets you decide to deploy into have access to the Internet, or at least 
an endpoint into wherever you decide to push the Docker image. The GitHub actions 
assume you have an ECR with appropriate permissions. You can alternatively build
the Docker image locally and push to whatever repository you want and alter the
parameters to your desire.

To deploy the stack, you can either use the AWS console, or the 
[StackUp](https://github.com/realestate-com-au/stackup) utility. Example
parameters are provided in `CloudFormation/Parameters.json`, and an example
of using StackUp is provided below:

```stackup simple-sinatra-app up --template CloudFormation/Stack.yaml --parameters CloudFormation/Parameters.json```

You will need to provide a VPC, at least two subnets (from different 
availability zones), and the location of the Docker image.

The output from the stack will be the ALB DNS endpoint.

## Assumptions and Design Choices

### This is a low-duty, predictable site

My solution does not have any provisions for dynamic scaling, so should the load
suddenly increase, there will be a constraint on the number of containers
running in ECS. Furthermore, this is not exposed as a parameter (nor are any
other ECS parameters), so it would be difficult to scale up suddenly.

### There are no other listeners on this ALB

My solution additionally assumes the default ALB route, so any additional
routes would require further work.

## Areas for Improvement

### Public IP Address for ECS Tasks

Ideally, I wouldn't have had a public IP address for the ECS tasks. Despite there
being security groups, and the risk being very low, there is no reason 
the ECS tasks need a public IP address. Unfortunately I was unable to pull Docker
images without assigning a public IP address. I tried associating NAT gateways
with the relevant subnets and unfortunately ran out of troubleshooting time, 
so resorted to allowing my tasks to have public IP addresses. A possible 
alternative would have been to create an endpoint between my VPC and ECR, but
I did not explore this.

### ALB exposed to Internet

There were no specific requirements around security, but were I to deploy
this for the public, I would want to use CloudFront (were this a static
website), or put it behind a WAF (should the content be dynamic.)

### No TLS

Again, there were no specific requirements around security, and the brief
specifically stated the site should be available on port 80, but I would
typically want to secure any website using TLS, likely using ACM (or LetsEncrypt.)

### The ECS task is way over-provisioned

Sadly, not much to be done there - the minimum vCPU is 0.25 and 512 MiB, 
but for such a simple application it seems unnecessary.