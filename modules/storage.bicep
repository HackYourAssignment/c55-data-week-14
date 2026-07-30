// Starter = Chapter 4 end state: one storage account + nested `raw` container.
// Task 1: accept an Environment tag (or tags object) from main and set it on the account.
// Task 2: keep `raw` and add a second nested container named `curated`.

param location string
param storageName string
param containerName string = 'raw'

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

output storageId string = storage.id
