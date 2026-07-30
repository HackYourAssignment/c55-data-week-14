// Starter = Chapter 4 end state (thin main + storage module).
// Assignment tasks EXTEND this template — do not replace it with a paste from
// azure-bicep-reference *-solution branches.
//
// Task 1: add an `environment` parameter and pass tags through to the module
//         (deploy with environment=dev, then what-if/create for environment=prod).
// Task 2: keep container `raw` and add a second nested container `curated`
//         (extend modules/storage.bicep).
targetScope = 'resourceGroup'

param location string = resourceGroup().location
param storageName string
param containerName string = 'raw'

// Dummy unused secret for hygiene practice — pass at deploy time, never commit the value
@secure()
param dbAdminPassword string

module storage 'modules/storage.bicep' = {
  name: 'storageDeploy'
  params: {
    location: location
    storageName: storageName
    containerName: containerName
  }
}

output storageId string = storage.outputs.storageId
