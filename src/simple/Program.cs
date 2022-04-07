using System;
using System.ComponentModel;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Bogus;
using Newtonsoft.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;

namespace Simple
{
    public class Inventory
    {
        public string Region { get; set; }
        public int InventoryCount { get; set; }
        public string InventoryType { get; set; }
        public string Manufacturer { get; set; }
        public string ActionType{get; set;}
        public string LocationId { get; set; }
    }




    class Program
    {
        static IConfiguration Configuration;
        // number of events to be sent to the event hub
        private const int numOfEvents = 1000;

        // The Event Hubs client types are safe to cache and use as a singleton for the lifetime
        // of the application, which is best practice when events are being published or read regularly.
        static EventHubProducerClient producerClient;
        static async Task Main(string[] args)
        {
            using IHost host = CreateHostBuilder(args).Build();
            //mapping static variable to strongly typed class
            var appSecrets = Configuration.GetSection(nameof(MyAppSecrets)).Get<MyAppSecrets>();

            var eventHubConnectionString = appSecrets.EventHubConnectionString;
            Console.WriteLine($"Event Hubs connection string: {eventHubConnectionString}");

            var eventHubName = appSecrets.EventHubName;
            Console.WriteLine($"Event Hubs name: {eventHubName}");

            var inventoryLocation = new string[]{
                "US",
                "EU",
                "ASIA"
            };
            var manufacturer = new string[]{
                "Apple",
                "Microsoft",
                "Dell",
                "Samsung",
                "LG"
            };

            var inventoryType = new string[]{
                "Store",
                "Warehouse"
            };

            var inventoryAction = new string[]{
                "Ship",
                "Stock"
            };

            var items = new Faker<Inventory>()
                .RuleFor(o => o.ActionType, f => f.PickRandom(inventoryAction))
                .RuleFor(o => o.InventoryType, f => f.PickRandom(inventoryType))
                .RuleFor(o => o.Region, f => f.PickRandom(inventoryLocation))
                .RuleFor(o => o.Manufacturer, f => f.PickRandom(manufacturer))
                .RuleFor(o => o.InventoryCount, f => f.Random.Number(0, 1000))
                .RuleFor(o => o.LocationId, (f,o) => o.Region+"-"+o.InventoryType+"-"+$"{f.Random.Number(0,10)}".PadLeft(2,'0'))
                .Generate(numOfEvents);
            
            // Console.WriteLine(JsonConvert.SerializeObject(items, Formatting.Indented));

            // Create a producer client that you can use to send events to an event hub
            producerClient = new EventHubProducerClient(eventHubConnectionString, eventHubName);
            // Create a batch of events 
            using EventDataBatch eventBatch = await producerClient.CreateBatchAsync();

            foreach (var item in items)
            {

                if (!eventBatch.TryAdd(new EventData(JsonConvert.SerializeObject(item))))
                {
                    // if it is too large for the batch
                    throw new Exception($"Event is too large for the batch and cannot be sent.");
                }
            }

            try
            {
                // Use the producer client to send the batch of events to the event hub
                await producerClient.SendAsync(eventBatch);
                Console.WriteLine($"A batch of {numOfEvents} events has been published.");
            }
            finally
            {
                await producerClient.DisposeAsync();
            }
            await host.RunAsync();
        }

        static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args).UseEnvironment("development")
            .ConfigureAppConfiguration((hostingContext, configuration) => {
                configuration.Sources.Clear();
                Configuration = configuration.AddUserSecrets<MyAppSecrets>().Build(); 
            });        
    }

}

public class MyAppSecrets{
    public string EventHubConnectionString { get; set; }
    public string EventHubName { get; set; }
}
