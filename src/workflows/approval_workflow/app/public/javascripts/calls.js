$(function() {
  
  /**
   * Make a request to the AWS Api Gateway to start a workflow execution
   * simulating an order
   */
  $("#start_execution").click(function() {
    $.ajax({
      type: "POST",
      url: env_variables.API_URL,
      headers: {
        'CORS': '*'
      },
      data: {
        "input": "{}",
        "name": Date.now(),
        "stateMachineArn": env_variables.SFN_ARN
      },
      success: function(data) {
        $("#response_start").html(data);
      },
      error: function(error) {
        $("#response_start").html(error);
      }
    });
  });

  /**
   * 
   */

});