# ElasticFlow

Computational distributable flows with stages.

Inspired by Flow, Spark, and Amazon's EMR.  Elastic Flow provides the structure to distribute an
enumerable data source to a cluster of servers and then aggregate into a result as data completes processing.

With Elastic Flow you create a Flow based program as normal; you'd then set your module in EF's config along with
your master/slave setup.  Work will then be distributed from master to your cluster to each server which are all running
the same program on each server, as a single BEAM app.  As work is completed the results are sent back to master to 
be aggregated.  There are default aggregation methods but the common usage will be to define your own aggregate method.

This is currently in the working proof of concept stage.  It fulfilled the author's (my) use case and as tested more is likely to be expanded on.
There is included an example that can be run from within the library locally to simulate a distributed system, which is a great way
to get a feel for the BEAM and Elastic Flow.

Scroll to the bottom if you wish to jump straight to an example.

[Full Documentation](https://hexdocs.pm/elastic_flow/0.0.1/ElasticFlow.html)

## Installation

Add `elastic_flow` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elastic_flow, "~> 0.0.1"}
  ]
end
```

And run mix deps.get

## Options

Elastic Flow has a couple of required options; namely to set your master and slave node sname's, and the task function that
will be run.  There are also optional settings shown here and used in the Example App:

```elixir
config :elastic_flow, 
  servers: %{
	:"yam1@baggy-the-cat" => :master, 
	:"yam2@baggy-the-cat" => :slave, 
	:"yam3@baggy-the-cat" => :slave
  },
  task: {ElasticFlow.Example, :count_words},
  aggregator: {ElasticFlow.Example, :aggregate}, # Optional
  intercept: ElasticFlow.ExampleInterceptor, # Optional
  compress: false # Optional (`true` does not currently work if your data includes type Tuple)
```

## More About ES Bits and Pieces

### Receipts

At every step of the way (sending, receiving, aggregation, ..) receipts are left behind that can track specific portions of the work. These receipts are hashed together using the chunk of data's time of first conception, the amount of entries and the stage it came from. More importantly, they can be matched at any part of the journey from distribution to aggregation.  Receipt matching could in theory be used to keep a soft real-time track on what work is completed or failed after the program is finished running.

In the future, receipts are hoped to carry enough data to be able to determine a retry on data.  That way if a server fails, the data can be retried on whichever is available.  Currently there is only enough there to see how much data was missed and from which server.

### Distributer

Run on the master node only; this takes the original data source, reads it into a Flow to distribute it via the master's sender to the clusters receivers.  In the future different distribution methods can be added.

### Aggregator

When processed data is returned to master, the aggregator runs an operation currently to countenance the data together as it arrives. The data needent be aggragated at all, if you only wish to record or emit a result for each piece or simply track when everything is completed.  There are default aggregate functions included in the protocol lib/elastic_flow/aggregation/aggregation_protocol.ex, which may work for some basic use cases.

## Example

Let's run the example first! We can use the library on it's on before creating a full app.  A word counter will be run, just like the example used in Flow's docs.  Estimated time: 5 minutes.

  Step 1: Clone the repository from github <https://github.com/Tyler-pierce/ElasticFlow.git>

    terminal 1> mix deps.get

  Step 2: Change the options in config/config.exs to use your computer name for the servers. The rest of the options are defaulted
  to use the word counting app.

    ```elixir
    config :elastic_flow, 
      servers: %{
        :"yam1@your-computer-name" => :master, 
        :"yam2@your-computer-name" => :slave, 
        :"yam3@your-computer-name" => :slave
      }
    ```

  Step 3: Now make sure you have 3 console windows/tabs open, and you can start your 3 'servers'
  
    terminal 1> iex --sname yam1 --cookie yamrider -S mix run
    terminal 2> iex --sname yam2 --cookie yamrider -S mix run
    terminal 3> iex --sname yam3 --cookie yamrider -S mix run

  Step 4: Run the convenience function to connect the servers (in production you'd have your cluster setup by your deployment or vm.args) and
  then run the program.

    iex(yam1@your-computer-name)1> ElasticFlow.Example.setup()

    iex(yam1@your-computer-name)1> ElasticFlow.Example.run()

    # You should see a lot of output because of the example apps custom interceptor.  Check the other tabs and you should see yam2
    and yam3 have received and sent data (and left receipts behind).  Feel free to take the interceptor out of the config to 
    avoid the noise.

  Step 5: Check your results!

    iex(yam1@your-computer-name)1> ElasticFlow.Example.results()

      %{"first" => 7, "whole" => 14, ... }

And that's it.  Have a look through the example folder code. I'll continue to update it as features progress so each integration point is obvious.

Cheers!
