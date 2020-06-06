# Backup Workflow
> ⚠️ Building this stack will generate cost in your billing dashboard, use it ONLY IF you understand the consequences ⚠️

This is a step functions workflow that demonstrates how you can implement signaling (pausing and processing external input) with the help of callbacks and AWS SQS.

## Architecture

!["Architecture Diagram"](./_assets/sfn_approval_workflow.png)

This workflow is more complex than `backup_workflow`, let's break down what's happening here:

1. Using the [AWS API Gateway]() we create an endpoint that will receive an `HTTP POST` request on the endpoint `https://<whatever_url_we_configure>/start/workflow`
2. The API endpoint will kickoff the step functions workflow execution
3. The starting point of the workflow / state machine is a [Lambda Function]() that will simulate an order being processed by some backend system
4. The state machine then transitions to a task that will push a message to SQS containing a `Task Token` and will pause while it waits to receive a success or fail callback
5. [SQS]() will receive the message and push it to the designated queue
6. Our local mini [Express]() app will expose a local endpoint and when it receives an `HTTP GET` request to `http://localhost:<port>/pending` it will pull a message from SQS and store it locally
7. Upon calling the locally exposed endpoint `http://localhost:<port>/approve` our app will send a `SendSuccess` directory to our state machine ordering it to move ot the next step
8. Based on the callback receive the state machine will move to Success or Failure 

## Structure

