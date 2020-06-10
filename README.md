# AWS Step Functions Lab
> This is a support repository for this blog post: [Planning on using AWS Step Functions? Think again](https://blog.bassemdy.com/2020/06/08/aws/architecture/microservices/patterns/aws-step-functions-think-again.html)

Please read the blog post 👆for context before exploring this repository. If you're feeling extra daring today, jump to Development Setup below for more instructions.

## Pre-requisites

OS X & Linux:

```sh
npm
Node.js v12.x.x+
Terraform: v0.12.x+
```

## Development setup

There are 2 projects in `src/workflows/` each with detailed instructions on how to run and use:

1. Backup workflow: [README.md](./src/workflows/backup_workflow/README.md)
2. Approval workflow: [README.md](./src/workflows/approval_workflow/README.md)

I recommend you start with the Backup workflow as it is simpler and easier to setup.

## Meta

Bassem Dghaidi – [@bassemdy](https://twitter.com/bassemdy)

Distributed under the Apache License v2.0. See ``LICENSE`` for more information.
