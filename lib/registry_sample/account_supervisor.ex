defmodule RegistrySample.AccountSupervisor do
  @moduledoc """
  Supervisor to handle the creation of dynamic `RegistrySample.Account` processes using a 
  `simple_one_for_one` strategy. See the `init` callback at the bottom for details on that.

  These processes will spawn for each `account_id` provided to the 
  `RegistrySample.Account.start_link` function.

  Functions contained in this supervisor module will assist in the creation and retrieval of 
  new account processes.

  Also note the guards utilizing `is_integer(account_id)` on the functions. My feeling here is that
  if someone makes a mistake and tries sending a string-based key or an atom, I'll just _"let it crash"_.
  """

  use Supervisor
  require Logger


  @account_registry_name :account_process_registry

  @doc """
  Starts the supervisor.
  """
  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)


  @doc """
  Will find the process identifier (in our case, the `account_id`) if it exists in the registry and
  is attached to a running `RegistrySample.Account` process.

  If the `account_id` is not present in the registry, it will create a new `RegistrySample.Account` 
  process and add it to the registry for the given `account_id`.

  Returns a tuple such as `{:ok, account_id}` or `{:error, reason}`
  """
  def find_or_create_process(account_id) when is_integer(account_id) do
    if account_process_exists?(account_id) do
      {:ok, account_id}
    else
      account_id |> create_account_process
    end
  end


  @doc """
  Determines if a `RegistrySample.Account` process exists, based on the `account_id` provided.

  Returns a boolean.

  ## Example
      iex> RegistrySample.AccountSupervisor.account_process_exists?(6)
      false
  """
  def account_process_exists?(account_id) when is_integer(account_id) do
    case Registry.lookup(@account_registry_name, account_id) do
      [] -> false
      _ -> true
    end
  end


  @doc """
  Creates a new account process, based on the `account_id` integer.

  Returns a tuple such as `{:ok, account_id}` if successful.
  If there is an issue, an `{:error, reason}` tuple is returned.
  """
  def create_account_process(account_id) when is_integer(account_id) do
    case Supervisor.start_child(__MODULE__, [account_id]) do
      {:ok, _pid} -> {:ok, account_id}
      {:error, {:already_started, _pid}} -> {:error, :process_already_exists}
      other -> {:error, other}
    end
  end


  @doc """
  Returns the count of `RegistrySample.Account` processes managed by this supervisor.

  ## Example
      iex> RegistrySample.AccountSupervisor.account_process_count
      0
  """
  def account_process_count, do: Supervisor.which_children(__MODULE__) |> length


  @doc """
  Return a list of `account_id` integers known by the registry.

  ex - `[1, 23, 46]`
  """
  def account_ids do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, account_proc_pid, _, _} ->
      Registry.keys(@account_registry_name, account_proc_pid)
      |> List.first
    end)
    |> Enum.sort
  end


  @doc """
  Return a list of widgets ordered per account.

  The list will be made up of a map structure for each child account process.

  ex - `[%{account_id: 2, widgets_sold: 1}, %{account_id: 10, widgets_sold: 1}]`
  """
  def get_all_account_widgets_ordered do
    account_ids() |> Enum.map(&(%{ account_id: &1, widgets_sold: RegistrySample.Account.widgets_ordered(&1) }))
  end


  @doc false
  def init(_) do
    children = [
      worker(RegistrySample.Account, [], restart: :temporary)
    ]

    # strategy set to `:simple_one_for_one` to handle dynamic child processes.
    supervise(children, strategy: :simple_one_for_one)
  end

end
