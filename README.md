# Event Sourcing

This repo contains the slides and code samples for my talk on Event Sourcing

The infrastructure can be configured to deploy using [these instructions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=userlevel%2CCLI)

To add secrets to the console app:

```powershell

dotnet user-secrets set "MyAppSecrets:EventHubConnectionString" "eventHubConnectionString"

```

```powershell

dotnet user-secrets set "MyAppSecrets:EventHubName" "eventHubName"

```
