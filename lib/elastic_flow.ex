defmodule ElasticFlow do
  @moduledoc ~S"""
  Computational distributable flows with stages.

  Inspired by Flow, Spark, and Amazon's EMR.  Elastic Flow provides a conceptual structure for distributing an
  enumerable data source to a cluster of servers and then aggregate into a result as data completes processing.

  With Elastic Flow you create a Flow based program as normal; you'd then set your module in Elastics config along with
  your master/slave setup.  Work will then be distributed from master to your cluster to each server which are all running
  the same program on each server, as a single BEAM app.  As work is completed the results are sent back to master to 
  be aggregated.  There are default aggregation methods but the common usage will be to define your own aggregate method.  By 
  defining an intercept module, actions can be viewed as they happen.

  This is currently in the working proof of concept stage.  It fulfilled the author's (my) use case and as tested more will be expanded.
  There is included an example that can be run from within the library locally to simulate a distributed system, which is a great way
  to get a feel for the BEAM and Elastic Flow.

  Flow:
  <https://github.com/elixir-lang/flow/>


  ## Example

  Let's run the example first! We can use the library on it's on before creating a full app.  A word counter will be run, just like
  the example used in Flow's docs.  Estimated time: 5 minutes.

  Step 1: Clone the repository from github <https://github.com/Tyler-pierce/ElasticFlow.git>

    ```
    terminal 1> mix deps.get
    ```

  Step 2: Change the options in config/config.exs to use your computer name for the servers. The rest of the options are defaulted
  to use the word counting app.

    ```
    config :elastic_flow, 
      servers: %{
        :"yam1@your-computer-name" => :master, 
        :"yam2@your-computer-name" => :slave, 
        :"yam3@your-computer-name" => :slave
      }
    ```

  Step 3: Now make sure you have 3 console windows/tabs open, and you can start your 3 'servers'
  
    ```
    terminal 1> iex --sname yam1 --cookie yamrider -S mix run
    ```
    ```
    terminal 2> iex --sname yam2 --cookie yamrider -S mix run
    ```
    ```
    terminal 3> iex --sname yam3 --cookie yamrider -S mix run
    ```

  Step 4: Run the convenience function to connect the servers (in production you'd have your cluster setup by your deployment or vm.args) and
  then run the program.

    ```
    iex(yam1@your-computer-name)1> ElasticFlow.Example.setup()
    ```
    ```
    iex(yam1@your-computer-name)1> ElasticFlow.Example.run()
    ```

    # You should see a lot of output because of the example apps custom interceptor.  Check the other tabs and you should see yam2
    and yam3 have received and sent data (and left receipts behind).  Feel free to take the interceptor out of the config to 
    avoid the noise.

  Step 5: Check your results!

    ```
    iex(yam1@your-computer-name)1> ElasticFlow.Example.results()

      %{"first" => 7, "whole" => 14, ... }
    ```

  And that's it.  If you wish to explore further try turning on the chaos_spirits option (from 1 to 45) to force errors, or adding longer jobs to try 
  step queueing.  And have a look through the example folder code to see how you'd structure your app. I'll continue to update it as features progress so each integration point
  is obvious.

  Cheers!

  Github README:
  <https://github.com/Tyler-pierce/ElasticFlow>
  """

  alias ElasticFlow.{Parcel, Step, Distributer, StepHandler}
  alias ElasticFlow.Error.MonitorDistribution

  @doc """
  Add a work routine to the distributed system. Note this is a work in progress. Steps in the future will be designed to
  run sequentially just as in EMR after a job is confirmed finished (by error or completion).

  ## Example

    iex> essay = File.stream!("lib/example/data/essay.txt")
    iex> ElasticFlow.create_step(essay) |> ElasticFlow.add_step()
  """
  def add_step(%Step{} = step) do
    StepHandler.add_step(step)
  end

  @doc """
  Create a step structure that can be used in functions that accept steps

  ## Example

    iex> ElasticFlow.create_step(file_stream) |> ElasticFlow.add_step()
  """
  def create_step(source) do
    %Step{enumerable_source: source}
  end

  @doc """
  Performs a retry on the last run step for any parcels that did not make it from distribution to 
  aggregation.  Uses receipt matching to achieve this.

  NOTE!! This is a placeholder. This feature is coming next release (0.1.1)

    iex> ElasticFlow.retry_step()
    .. (results) ..
  """
  def retry_step() do
    :not_implemented
  end

  @doc """
  An initialization step that can be called to automatically connect the server nodes into a
  cluster and setup appropriate monitoring for maximum error recovery/coverage.  In short it is
  a recommended/common use setup. Returns a list of connection results for your server list.

  ## Example

    iex> ElasticFlow.init()
    [:master, true, true]
  """
  def init() do
    connected_servers = for key <- Map.keys(Application.get_env(:elastic_flow, :servers)) do
      case Map.get(Application.get_env(:elastic_flow, :servers), key) do
        :master ->
          :master
        _ ->
          Node.connect key
      end
    end

    connected_servers
  end

  @doc """
  Setup error monitoring to help recover from errors on nodes or nodes going down

  ## Example

    iex> ElasticFlow.init()
    [:master, true, true]
    iex> ElasticFlow.monitor()
    :ok
  """
  def monitor() do
    MonitorDistribution.setup_monitoring()
  end

  @doc """
  Takes a flow and distributes it's payload evenly among the master and workers.
  Note that in the future different distribution strategies can be added (master doesn't process work, 
  distributed to server with fewest open receipts, etc..). Default options make use of amount of
  servers = amount stages.

  ## Example

    iex> ElasticFlow.create_step(file_stream) |> ElasticFlow.add_step()
  """
  def distribute(%Flow{} = flow, options \\ []) do

    window = case Application.get_env(:elastic_flow, :distribute_window, true) do
      {module, function} ->
        apply(module, function, [])
      true ->
        get_distribute_window()
    end

    options_with_defaults = Keyword.merge(options, [stages: get_server_count(), window: window])

    Flow.partition(flow, options_with_defaults)
      |> Flow.reduce(fn -> [] end, fn item, acc ->         
        [item|acc]
      end)
      |> Flow.each_state(fn item_list, {partition_number, _amt_stages} -> 
        Distributer.package_and_send(%Parcel{payload: item_list, partition: partition_number})
      end)
      |> Flow.run()
  end

  defp get_distribute_window() do
    Flow.Window.global() |> Flow.Window.trigger_every(3000, :reset)
  end

  defp get_server_count() do
    configured_servers = Application.get_env(:elastic_flow, :servers)

    Enum.count(configured_servers)
  end
end
