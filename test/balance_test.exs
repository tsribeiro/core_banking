defmodule CoreBanking.BalanceTest do
  use ExUnit.Case, async: true

  setup do
    account_id = Enum.random(0..1000)
    {:ok, balance} =
      DynamicSupervisor.start_child(
        CoreBanking.BalanceSupervisor,
        {CoreBanking.Balance, account_id: account_id}
      )

    on_exit(fn ->
      CoreBanking.AccountBalance.filter_by_account_id(account_id)
      |> Enum.each(&CoreBanking.Repo.delete(&1))
    end)

    %{balance: balance}
  end

  test "deposit amount", %{balance: balance} do
    assert CoreBanking.Balance.deposit(balance, 1000) == {:ok, %{kind: :cash_in, amount: 1000}}
  end

  test "withdrawal less than balance", %{balance: balance} do
    CoreBanking.Balance.deposit(balance, 1000)

    assert CoreBanking.Balance.withdraw(balance, 100) == {:ok, %{kind: :cash_out, amount: 100}}
  end

  test "get balance", %{balance: balance} do
    CoreBanking.Balance.deposit(balance, 1000)
    CoreBanking.Balance.withdraw(balance, 100)

    assert CoreBanking.Balance.get(balance) == 900
  end

  test "withdrawal more than balance", %{balance: balance} do
    assert CoreBanking.Balance.withdraw(balance, 100) == {:error, %{code: :insufficient_funds}}
  end
end
