import random
# This function does absolutely nothing other than
# return True or raise an exception based on a randomly generated value
def handler(event, context):
  if random.random() > 0.5:
    return {
      'IsBackupSuccessful' : True
    }
  else:
    raise Exception("Backup simulation failed.")
