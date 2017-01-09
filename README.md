# RegistrySample

Example application using the new `Registry` module in Elixir 1.4

See this [blog post](https://medium.com/@adammokan/registry-in-elixir-1-4-0-d6750fb5aeb#.7cnipan20) for more context.

## The Basics

### Clone the Repo

`git clone git@github.com:amokan/registry_sample.git`

### Run the sample in IEX

```
cd registry_sample
iex -S mix
```

### Scenario

From the [blog post](https://medium.com/@adammokan/registry-in-elixir-1-4-0-d6750fb5aeb#.7cnipan20):

_Imagine we have a scenario where we are selling widgets to customers. Our boss wants us to build a realtime UI that shows every account that has placed an order in the current day along with some basic info about each account. If an account doesn’t place another order within 24 hours, it should fall off the UI_

### RegistrySample.AccountSupervisor

The `RegistrySample.AccountSupervisor` is a `:simple_one_for_one` supervisor that gives us a few helpful functions for creating new `RegistrySample.Account` processes and indicating which processes are already running.

Let's create an account process for `account_id` # 2 and `account_id` # 10.
```
iex> RegistrySample.AccountSupervisor.find_or_create_process(2)
{:ok, 2}

iex> RegistrySample.AccountSupervisor.find_or_create_process(10)
{:ok, 2}

iex> RegistrySample.AccountSupervisor.get_all_account_widgets_ordered
[%{account_id: 2, widgets_sold: 1}, %{account_id: 10, widgets_sold: 1}]
```

Now we can say that `account_id` # 10 ordered another widget, by just passing the `account_id`

```
iex> RegistrySample.Account.order_widget(10)
:ok

iex> RegistrySample.AccountSupervisor.get_all_account_widgets_ordered
[%{account_id: 2, widgets_sold: 1}, %{account_id: 10, widgets_sold: 2}]
```

