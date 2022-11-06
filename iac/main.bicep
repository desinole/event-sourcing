@description('Name of EventHub namespace')
param namespaceName string = 'evhns-${uniqueString(resourceGroup().id)}'

@description('The messaging tier for service Bus namespace')
@allowed([
  'Basic'
  'Standard'
])
param eventhubSku string = 'Standard'

@description('MessagingUnits for premium namespace')
@allowed([
  1
  2
  4
])
param skuCapacity int = 1

@description('Name of Event Hub')
param eventHubName string = 'evh-${uniqueString(resourceGroup().id)}'

@description('Name of Consumer Group')
param consumerGroupName string = 'cg-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of Authorization Rule')
param authorizationRole string = 'auth-${uniqueString(resourceGroup().id)}'


@description('Stream Analytics Job Name, can contain alphanumeric characters and hypen and must be 3-63 characters long')
@minLength(3)
@maxLength(63)
param streamAnalyticsJobName string = 'asa-${uniqueString(resourceGroup().id)}'

@description('Number of Streaming Units')
@minValue(1)
@maxValue(48)
@allowed([
  1
  3
  6
  12
  18
  24
  30
  36
  42
  48
])
param numberOfStreamingUnits int = 6

param asaTranformationName string = 'asaTranformation-${uniqueString(resourceGroup().id)}'

param asaInputName string = 'asaInput-${uniqueString(resourceGroup().id)}'

param asaOutputName string = 'asaOutputName-${uniqueString(resourceGroup().id)}'

@description('Cosmos DB account name, max length 44 characters, lowercase')
param accountName string = 'sql-${uniqueString(resourceGroup().id)}'

@description('The default consistency level of the Cosmos DB account.')
@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param defaultConsistencyLevel string = 'Session'

@description('The name for the database')
param databaseName string = 'db-${uniqueString(resourceGroup().id)}'

@description('The name for the container')
param containerName string = 'container-${uniqueString(resourceGroup().id)}'

@description('Maximum throughput for the container')
@minValue(4000)
@maxValue(1000000)
param autoscaleMaxThroughput int = 4000

@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.')
@minValue(10)
@maxValue(2147483647)
param maxStalenessPrefix int = 100000

@description('Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
@minValue(5)
@maxValue(86400)
param maxIntervalInSeconds int = 300


var accountName_var = toLower(accountName)
var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]

@description('The name of the function app that you wish to create.')
param appName string = 'fnapp${uniqueString(resourceGroup().id)}'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('The language worker runtime to load in the function app.')
@allowed([
  'node'
  'dotnet'
  'java'
])
param runtime string = 'dotnet'

var functionAppName_var = appName
var hostingPlanName_var = appName
var applicationInsightsName_var = appName
var storageAccountNameValue = 'st${uniqueString(resourceGroup().id)}'
var functionWorkerRuntime = runtime

resource namespaceName_resource 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: namespaceName
  location: location
  sku: {
    name: eventhubSku
    tier: eventhubSku
    capacity: skuCapacity
  }
  tags: {}
  properties: {}
}

resource namespaceName_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  parent: namespaceName_resource
  name: eventHubName
  properties: {
    partitionCount: 2
  }
}

resource namespaceName_eventHubName_consumerGroupName 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2017-04-01' = {
  parent: namespaceName_eventHubName
  name: consumerGroupName
  properties: {}
}

resource namespaceName_eventHubName_authorizationRole 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-11-01' = {
  name: authorizationRole
  parent: namespaceName_eventHubName
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource streamAnalyticsJobName_resource 'Microsoft.StreamAnalytics/StreamingJobs@2019-06-01' = {
  name: streamAnalyticsJobName
  location: location
  properties: {
    sku: {
      name: 'standard'
    }
    outputErrorPolicy: 'stop'
    eventsOutOfOrderPolicy: 'adjust'
    eventsOutOfOrderMaxDelayInSeconds: 0
    eventsLateArrivalMaxDelayInSeconds: 5
    dataLocale: 'en-US'
  }
}

resource streamAnalyticsJobName_transform 'Microsoft.StreamAnalytics/streamingjobs/transformations@2020-03-01' = {
  name: asaTranformationName
  parent: streamAnalyticsJobName_resource
  properties: {
    query: 'SELECT\r\n    *\r\nINTO\r\n    [${asaOutputName}]\r\nFROM\r\n    [${asaInputName}]'
    streamingUnits: numberOfStreamingUnits
  }
}

resource streamAnalyticsJobName_input 'Microsoft.StreamAnalytics/streamingjobs/inputs@2020-03-01' = {
  name: asaInputName
  parent: streamAnalyticsJobName_resource
  properties: {
    compression: {
      type: 'None'
    }
    serialization: {
      type: 'Json'  
      properties: {
        encoding: 'UTF8'
      }
    }
    type: 'Stream'
    datasource:{
      type: 'Microsoft.EventHub/EventHub'
      properties: {
        authenticationMode: 'ConnectionString'
        consumerGroupName: consumerGroupName
        eventHubName: eventHubName
        serviceBusNamespace: namespaceName
        sharedAccessPolicyName: authorizationRole
        sharedAccessPolicyKey: namespaceName_eventHubName_authorizationRole.listKeys().primaryKey
      }
    }
  }
}

resource streamAnalyticsJobName_output 'Microsoft.StreamAnalytics/streamingjobs/outputs@2020-03-01' = {
  name: asaOutputName
  parent: streamAnalyticsJobName_resource
  properties: {
    datasource: {
      type: 'Microsoft.Storage/DocumentDB'
      properties: {
          collectionNamePattern: containerName
          accountKey: accountName_resource.listKeys().primaryMasterKey
          accountId: accountName
          database: databaseName
      }
    }
  }
}

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: accountName_var
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-01-15' = {
  parent: accountName_resource
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource accountName_databaseName_containerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-01-15' = {
  parent: accountName_databaseName
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/LocationId'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        spatialIndexes: [
          {
            path: '/path/to/geojson/property/?'
            types: [
              'Point'
              'Polygon'
              'MultiPolygon'
              'LineString'
            ]
          }
        ]
      }
      defaultTtl: 86400
    }
    options: {
      autoscaleSettings: {
        maxThroughput: autoscaleMaxThroughput
      }
    }
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountNameValue
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    name: hostingPlanName_var
    computeMode: 'Dynamic'
  }
}

resource functionAppName 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName_var
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlanName.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountNameValue};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountNameValue};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName.id, '2019-06-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName_var)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(applicationInsightsName.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'COSMOS_DB_CONNECTION_STRING'
          value: accountName_resource.listConnectionStrings().connectionStrings[0].connectionString
        }
      ]
    }
  }
}

resource applicationInsightsName 'microsoft.insights/components@2020-02-02-preview' = {
  name: applicationInsightsName_var
  location: location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', applicationInsightsName_var)}': 'Resource'
  }
  properties: {
    ApplicationId: applicationInsightsName_var
    Request_Source: 'IbizaWebAppExtensionCreate'
  }
}
