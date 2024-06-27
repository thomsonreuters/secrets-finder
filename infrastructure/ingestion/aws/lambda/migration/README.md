# Migration Lambda

This directory contains all the necessary scripts to package Migrations (located at the root level) as a Lambda function.

The packaging process uses the Poetry Lambda plugin and leverages Docker to ensure Lambda packages are generated for the correct platform.

## Usage

To package lambda, run following command

```bash
./package.sh
```

> [!NOTE]
> Any changes in Migrations should be automatically detected during the repackaging process.
