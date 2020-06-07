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

/* GET /pending - returns list of pending orders */
router.get('/pending', function(req, res, next) {
  
  var params = {
    AttributeNames: [
       "SentTimestamp"
    ],
    MaxNumberOfMessages: 10,
    MessageAttributeNames: [
       "All"
    ],
    QueueUrl: queueURL,
    VisibilityTimeout: 20,
    WaitTimeSeconds: 0
  };

  sqs.receiveMessage(params, function(err, data) {
    if (err) {
      res.send("Received Error", err);
    } else if (data.Messages) {
      res.send(data.Messages)
    }
  });
});

/* POST /approval - approve / reject pending orders */
router.post('/approval', function(req, res, next) {
  res.send('approval / rejection');
});

module.exports = router;
