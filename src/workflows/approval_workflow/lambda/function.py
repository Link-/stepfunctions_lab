# Mock lambda to simulate an order being process
# always succeeds
def handler(event, context):
  return {
    'IsOrderProcessed' : True
  }
