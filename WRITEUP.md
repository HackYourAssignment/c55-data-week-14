# Write-up

I extended the existing Bicep starter instead of rebuilding it from an empty file. The main template now has an `environment` parameter with the values `dev` and `prod`. This value is passed to the storage module and becomes the `Environment` tag on the storage account. The same Bicep files can therefore describe different environments without copying the infrastructure code.

The storage module still creates the original nested `raw` container and now also creates a second nested container named `curated`. The `raw` container can hold data as it first arrives, while `curated` can hold data that has been cleaned or prepared for further use. Both containers use the default blob service and `parent:` so Azure understands their relationship to the storage account.
