# Backup Workflow

## Structure

## Run

```sh
# Go to the lambda directory
cd ./lambda

# Zip the lambda function so that we push the zip file to AWS
zip payload.zip function.py

# Go to the terraform directory to apply the stack
cd ../terraform

# Dry-run
terraform plan \
  --var="lambda_function_payload="(pwd)"/../lambda/payload.zip" \
  --var="sfn_state_machine_definition="(pwd)"/../state_machine_definition.json.tpl"

# Build the stack
terraform apply \
  --var="lambda_function_payload="(pwd)"/../lambda/payload.zip" \
  --var="sfn_state_machine_definition="(pwd)"/../state_machine_definition.json.tpl"

# Destroy the stack
terraform destroy \
  --var="lambda_function_payload="(pwd)"/../lambda/payload.zip" \
  --var="sfn_state_machine_definition="(pwd)"/../state_machine_definition.json.tpl"
```