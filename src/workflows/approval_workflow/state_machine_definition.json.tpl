{
  "Comment": "This is a simulation of an approval workflow. The execution will pause pending a confirmation through the app.",
  "StartAt": "Process Order",
  "States": {
    "Process Order": {
      "Comment": "This step will trigger the lambda to intiate order processing simulation.",
      "Type": "Task",
      "Resource": "${order_process_lambda_arn}",
      "Next": "Request Approval"
    },
    "Request Approval": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage.waitForTaskToken",
      "Parameters": {
        "QueueUrl": "${order_sqs_url}",
        "MessageBody": {
          "MessageTitle": "Processing Order, approve / reject to proceed.",
          "TaskToken.$": "$$.Task.Token"
        }
      },
      "Next": "Success",
      "Catch": [
        {
          "ErrorEquals": [ "States.ALL" ],
          "Next": "Failure"
        }
      ]
    },
    "Success": {
      "Type": "Pass",
      "End": true
    },
    "Failure": {
      "Type": "Fail",
      "Cause": "Order processing failed or denied",
      "Error": "Request Approval returned FAILED"
    }
  }
}
