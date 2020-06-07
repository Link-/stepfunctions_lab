var express = require('express');
var router = express.Router();
// Load the AWS SDK for Node.js
var AWS = require('aws-sdk');
// Set the region 
var region = process.env.AWS_REGION || 'eu-west-1';
AWS.config.update({region: region});

// Create an SQS service object
var sqs = new AWS.SQS({apiVersion: '2012-11-05'});
var queueURL = process.env.QUEUE_URL;

// Create Step Functions service object
var sfn = new AWS.StepFunctions();

/* GET /pending - returns list of pending orders */
router.get('/pending', function(req, res, next) {
  
  var params = {
    AttributeNames: [
       "SentTimestamp"
    ],
    MaxNumberOfMessages: 1,
    MessageAttributeNames: [
       "All"
    ],
    QueueUrl: queueURL,
    VisibilityTimeout: 60,
    WaitTimeSeconds: 0
  };

  sqs.receiveMessage(params, function(err, data) {
    if (err) {
      console.log(err);
      res.send("Received Error", err);
    } else if (data.Messages) {
      res.send(data.Messages)
    }
  });
});

/* POST /approval - approve pending orders */
router.post('/approval', function(req, res, next) {
  var sfnParams = {
    output: '{ "status": "SUCCESS" }',
    taskToken: req.body.token
  };

  var sqsParams = {
    QueueUrl: process.env.QUEUE_URL,
    ReceiptHandle: req.body.receiptHandle
  }
  // Send the TaskSuccess to Step Functions
  sfn.sendTaskSuccess(sfnParams, function(err, data) {
    if (err) {
      console.log(`StepFunctions Fail: ${err}`);
      res.status(500).json({status: 'failed'})
    } else {
      // Delete the message from the Queue
      sqs.deleteMessage(sqsParams, function(err, data) {
        if (err) {
          console.log(`SQS Fail: ${err}`);
          res.status(500).json({status: 'failed'})
        } else {
          console.log(data);
          res.status(200).json({status: 'ok'})
        }
      });
    }
  })
});

module.exports = router;
