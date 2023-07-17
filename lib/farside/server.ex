defmodule Farside.Server do
  use GenServer
  import Crontab.CronExpression

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(arg) do
    test = System.get_env("FARSIDE_TEST")
    cron = System.get_env("FARSIDE_CRON")

    if test == "1" || cron == "0" do
      IO.puts("Skipping sync job setup...")
    else
      Farside.Scheduler.new_job()
      |> Quantum.Job.set_name(:sync)
      |> Quantum.Job.set_schedule(~e[*/5 * * * *])
      |> Quantum.Job.set_task(fn -> Farside.Instances.sync() end)
      |> Farside.Scheduler.add_job()
    end

    GenServer.start_link(__MODULE__, arg)
  end
end
