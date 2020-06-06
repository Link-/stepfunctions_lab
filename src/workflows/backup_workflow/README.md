# Backup Workflow

## Structure

## Run

```sh
# Run the build script to generate the lambda function payload
build.sh

# Dry-run
terraform plan \
  --var="lambda_function_payload="(pwd)"/lambda/payload.zip" \
  --var="sfn_state_machine_definition="(pwd)"/state_machine_definition.json.tpl" \
  terraform

# Build the stack
terraform apply \
  --var="lambda_function_payload="(pwd)"/lambda/payload.zip" \
  --var="sfn_state_machine_definition="(pwd)"/state_machine_definition.json.tpl" \
  terraform

# Destroy the stack
terraform destroy \
  --var="lambda_function_payload="(pwd)"/lambda/payload.zip" \
  --var="sfn_state_machine_definition="(pwd)"/state_machine_definition.json.tpl" \
  terraform
```