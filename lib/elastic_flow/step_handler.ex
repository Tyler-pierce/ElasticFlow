defmodule ElasticFlow.StepHandler do
  @moduledoc false
  use GenServer

  alias ElasticFlow.Step
  alias ElasticFlow.Persistance.StepData


  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :step_handler)
  end

  def init(:ok) do
    {:ok, %{steps: :queue.new, statuses: [], error_count: 0}}
  end

  # Client
  ##########################
  def add_step(%Step{} = step) do
    case GenServer.call(:step_handler, {:add_step, step}) do
      :in_progress ->
      	:step_added
      _ ->
      	play_step()
    end
  end

  def play_step() do
  	GenServer.call(:step_handler, :play_step)
  end

  def increment_error_count() do
  	GenServer.cast(:step_handler, :increment_error_count)
  end

  def get_error_count() do
  	GenServer.call(:step_handler, :error_count)
  end

  def get_current_step_id() do
  	results = get_results(:all)

    # Steps are just run sequentially and the index is its number in the queue essentially.
    # Run 2nd == index 2 (by virtue of guarantees in this service)
  	Enum.count(results)
  end

  # This need be called before being able to advance the step queue (when blocked by :in_progress status)
  def signal_step(new_status) do
  	GenServer.call(:step_handler, {:signal_step, new_status})
  end

  def get_results(which \\ :all) do
  	results = GenServer.call(:step_handler, :statuses)

  	case which do
  	  :all ->
  	  	results
  	  :first ->
  	  	[first|_] = results
  	  	first
  	end
  end

  # Server
  ##########################
  def handle_call(:statuses, _from, %{statuses: statuses} = state) do
  	{:reply, statuses, state}
  end

  def handle_call({:add_step, %Step{} = step}, _from, %{steps: q, statuses: statuses} = state) do
    q = :queue.in(step, q)

    current_status = case statuses do
      [current_status|_] ->
      	current_status
      _ ->
      	nil
    end

    {:reply, current_status, %{state | :steps => q}}
  end

  def handle_call({:signal_step, :complete}, _from, %{statuses: [_current_status|statuses]} = state) do
  	{:reply, :ok, %{state | :statuses => [:complete|statuses]}}
  end

  def handle_call({:signal_step, :complete_with_retries}, _from, %{statuses: [_current_status|statuses]} = state) do
  	{:reply, :ok, %{state | :statuses => [:complete_with_retries|statuses]}}
  end

  def handle_call({:signal_step, :error}, _from, %{statuses: [_current_status|statuses]} = state) do
  	{:reply, :ok, %{state | :statuses => [:error|statuses]}}
  end

  def handle_call({:signal_step, _}, _from, state) do
  	{:reply, :invalid_status_update, state}
  end

  # Possible results returned:
  # :step_already_in_progress - currently running
  # :ok - started step
  # :no_steps - queue is empty
  # :error_distribution_flow - if distribution setup unsucessful (issue with enumerable source? bad options?)
  def handle_call(:play_step, _from, %{statuses: [:in_progress|_]} = state) do
  	{:reply, :step_already_in_progress, state}
  end

  def handle_call(:play_step, _from, %{steps: q, statuses: statuses} = state) do
  	{result, q, status} = case :queue.out(q) do
  	  {{:value, %Step{enumerable_source: source}}, q} ->
  	  	_ = StepData.init_step(Enum.count(statuses) + 1)

  	  	flow = cond do
  	  	  is_list(source) ->
  	  	  	source
              |> Flow.from_enumerables()
          true ->
            source
              |> Flow.from_enumerable()
  	  	end

  	  	try do
  	  	  # Will expand supervisor tree to handle this without try/rescue
	  	  :ok = flow
	        |> ElasticFlow.distribute(Application.get_env(:elastic_flow, :distribute_options, []))

	      {:ok, q, :in_progress}
        rescue
          _ -> {:error_distribution_flow, q, nil}
        end
  	  {:empty, q} ->
  	  	{:no_steps, q, nil}
  	end

  	state_final = case status do
  	  nil ->
  	  	%{state | :steps => q}
  	  status ->
  	  	%{state | :statuses => [status|statuses], :steps => q}
  	end

  	{:reply, result, state_final}
  end

  def handle_call(:results, _from, %{results: results} = state) do
  	{:reply, results, state}
  end

  def handle_call(:error_count, _from, %{error_count: error_count} = state) do
  	{:reply, error_count, state}
  end

  def handle_cast(:increment_error_count, %{error_count: error_count} = state) do
  	{:noreply, %{state | :error_count => error_count + 1}}
  end

  def handle_info(_, state), do: {:noreply, state}
end