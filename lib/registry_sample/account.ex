defmodule RegistrySample.Account do
  @moduledoc """
  Simple genserver to represent an imaginary account process.

  Requires you provide an integer-based `account_id` upon starting.

  There is a `:fetch_data` callback handler where you could easily get additional account attributes
  from a database or some other source - assuming the `account_id` provided was a valid key to use as
  database criteria.
  """

  use GenServer
  require Logger

  @account_registry_name :account_process_registry
  @process_lifetime_ms 86_400_000 # 24 hours in milliseconds - make this number shorter to experiement with process termination

  # Just a simple struct to manage the state for this genserver
  # You could add additional attributes here to keep track of for a given account
  defstruct account_id: 0,
            name: "",
            some_attribute: "",
            widgets_ordered: 1,
            timer_ref: nil


  @doc """
  Starts a new account process for a given `account_id`.
  """
  def start_link(account_id) when is_integer(account_id) do
    GenServer.start_link(__MODULE__, [account_id], name: via_tuple(account_id))
  end


  # registry lookup handler
  defp via_tuple(account_id), do: {:via, Registry, {@account_registry_name, account_id}}


  @doc """
  Return some details (state) for this account process
  """
  def details(account_id) do
    GenServer.call(via_tuple(account_id), :get_details)
  end


  @doc """
  Return the number of widgets ordered by this account
  """
  def widgets_ordered(account_id) do
    GenServer.call(via_tuple(account_id), :get_widgets_ordered)
  end


  @doc """
  Function to indicate that this account ordered a widget
  """
  def order_widget(account_id) do
    GenServer.call(via_tuple(account_id), :order_widget)
  end


  @doc """
  Returns the pid for the `account_id` stored in the registry
  """
  def whereis(account_id) do
    case Registry.lookup(@account_registry_name, account_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end


  @doc """
  Init callback
  """
  def init([account_id]) do

    # Add a msg to the process mailbox to
    # tell this process to run `:fetch_data`
    send(self(), :fetch_data)
    send(self(), :set_terminate_timer)

    Logger.info("Process created... Account ID: #{account_id}")

    # Set initial state and return from `init`
    {:ok, %__MODULE__{ account_id: account_id }}
  end


  @doc """
  Our imaginary callback handler to get some data from a DB to
  update the state on this process.
  """
  def handle_info(:fetch_data, state = %{account_id: account_id}) do

    # update the state from the DB in imaginary land. Hardcoded for now.
    updated_state =
      %__MODULE__{ state | widgets_ordered: 1, name: "Account #{account_id}" }

    {:noreply, updated_state}
  end

  @doc """
  Callback handler that sets a timer for 24 hours to terminate this process.

  You can call this more than once it will continue to `push out` the timer (and cleans up the previous one)

  I could have combined the logic below and used just one callback handler, but I like seperating the
  concern of creating an initial timer reference versus destroying an existing one. But that is up to you.
  """
  def handle_info(:set_terminate_timer, %__MODULE__{ timer_ref: nil } = state) do
    # This is the first time we've dealt with this account, so lets set our timer reference attribute
    # to end this process in 24 hours from now

    # set a timer for 24 hours from now to end this process
    updated_state =
      %__MODULE__{ state | timer_ref: Process.send_after(self(), :end_process, @process_lifetime_ms) }

    {:noreply, updated_state}
  end
  def handle_info(:set_terminate_timer, %__MODULE__{ timer_ref: timer_ref } = state) do
    # This match indicates we are in a situation where `state.timer_ref` is not nil -
    # so we already have dealt with this account before

    # let's cancel the existing timer
    timer_ref |> Process.cancel_timer

    # set a new timer for 24 hours from now to end this process
    updated_state =
      %__MODULE__{ state | timer_ref: Process.send_after(self(), :end_process, @process_lifetime_ms) }

    {:noreply, updated_state}
  end


  @doc """
  Gracefully end this process
  """
  def handle_info(:end_process, state) do
    Logger.info("Process terminating... Account ID: #{state.account_id}")
    {:stop, :normal, state}
  end


  @doc false
  def handle_call(:get_details, _from, state) do

    # maybe you'd want to transform the state a bit...
    response = %{
      id: state.account_id,
      name: state.name,
      some_attribute: state.some_attribute,
      widgets_ordered: state.widgets_ordered
    }

    {:reply, response, state}
  end


  @doc false
  def handle_call(:get_widgets_ordered, _from, %__MODULE__{ widgets_ordered: widgets_ordered } = state) do
    {:reply, widgets_ordered, state}
  end


  @doc false
  def handle_call(:order_widget, _from, %__MODULE__{ widgets_ordered: widgets_ordered } = state) do
    {:reply, :ok, %__MODULE__{ state | widgets_ordered: widgets_ordered + 1 }}
  end

end
