defmodule BinFormat.FieldServer do
  use GenServer

  def start_link(module) do
    GenServer.start_link(__MODULE__, [], name: server_name(module))
  end

  def stop(module) do
    GenServer.cast(server_name(module), :stop)
  end

  def add_field(module, field) do
    GenServer.cast(server_name(module), {:add_field, field})
  end

  def get_fields(module) do
    GenServer.call(server_name(module), :get_fields)
  end

  defp server_name(module) do
    String.to_atom("BinFormat.FieldServer." <> Atom.to_string(module))
  end

  def init([]) do
    {:ok, []}
  end

  def handle_call(:get_fields, _, fields) do
    {:reply, Enum.reverse(fields), fields}
  end

  def handle_cast({:add_field, field}, fields) do
    {:noreply, [field | fields]}
  end

  def handle_cast(:stop, fields) do
    {:stop, :normal, fields}
  end

end
