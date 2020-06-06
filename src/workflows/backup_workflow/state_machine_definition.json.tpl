{
  "Comment": "This is a simulation of a backup workflow. The lambda will execute and return either a success or fail randomly to simulate different behaviors.",
  "StartAt": "Start Backup",
  "States": {
    "Start Backup": {
      "Comment": "This step will trigger the lambda to intiate the backup process.",
      "Type": "Task",
      "Resource": "${backup_lambda_arn}",
      "Next": "Backup Successful?"
    },
    "Backup Successful?": {
      "Comment": "A Choice state adds branching logic to a state machine. Choice rules can implement 16 different comparison operators, and can be combined using And, Or, and Not",
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.IsBackupSuccessful",
          "BooleanEquals": true,
          "Next": "Yes"
        },
        {
          "Variable": "$.IsBackupSuccessful",
          "BooleanEquals": false,
          "Next": "No"
        }
      ],
      "Default": "No"
    },
    "Yes": {
      "Type": "Pass",
      "Next": "Wait 3 sec"
    },
    "No": {
      "Type": "Fail",
      "Cause": "Backup Failed"
    },
    "Wait 3 sec": {
      "Comment": "A Wait state delays the state machine from continuing for a specified time.",
      "Type": "Wait",
      "Seconds": 3,
      "Next": "Backup Success!"
    },
    "Backup Success!": {
      "Type": "Pass",
      "End": true
    }
  }
}
