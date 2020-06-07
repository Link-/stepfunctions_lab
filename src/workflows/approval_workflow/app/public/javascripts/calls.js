$(function() {
  
  /**
   * Make a request to the AWS Api Gateway to start a workflow execution
   * simulating an order
   */
  $("#start_execution").click(function() {
    $.ajax({
      type: "POST",
      url: env_variables.API_URL,
      dataType: 'json',
      data: JSON.stringify({
        "input": "{}",
        "name": `${Date.now()}`,
        "stateMachineArn": env_variables.SFN_ARN
      }),
      success: function(data) {
        var jsonString = JSON.stringify(data);
        $("#response_start").html(`<pre>${jsonString}</pre>`);
      },
      error: function(error) {
        $("#response_start").html(error);
      }
    });
  });

  /**
   * Fetch pending requests and render them.
   */
  $("#get_pending_orders").click(function() {
    // Clear up the holder
    $("#response_process").html('');

    $.ajax({
      type: "GET",
      url: "/api/pending",
      dataType: 'json',
      success: function(data) {
        // Add the elements
        data.forEach((order) => {
          var parsedBody = JSON.parse(order.Body);
          var element = `
<div>
  <p>${order.MessageId}</p>
  <button class='process_order' data-ReceiptHandle='${order.ReceiptHandle}' data-MessageId='${order.MessageId}' data-TaskToken='${parsedBody.TaskToken}'>Approve</button>
  <button class='process_order' data-ReceiptHandle='${order.ReceiptHandle}' data-MessageId='${order.MessageId}' data-TaskToken='${parsedBody.TaskToken}'>Reject</button>
  <hr />
</div>
`
          $("#response_process").append(element);
        });
      },
      error: function(error) {
        $("#response_process").html(error);
      }
    });
  });

  /**
   * Process message
   */
  $("#response_process").on('click', '.process_order', function() {
    var requestPayload = {
      "token": $(this).attr('data-TaskToken'),
      "receiptHandle": $(this).attr('data-ReceiptHandle')
    };
    var messageId = $(this).attr('data-MessageId');
    var elementsParent = $(this).parent('div');

    $.ajax({
      type: "POST",
      url: "/api/approval",
      dataType: 'json',
      data: requestPayload,
      success: function(data) {
        $("#approval_process").html(`${messageId} has been processed successfully!`);
        $(elementsParent).remove();
      },
      error: function(error) {
        $("#approval_process").html(error);
      }
    });
  });

});