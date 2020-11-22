defmodule CasksBarrels.RoomManager do
  use GenServer

  @answer_timeout 30_000

  alias CasksBarrels.Room

  def start_link(_args) do
    GenServer.start_link(__MODULE__, Room.new(), name: __MODULE__)
  end

  def register_player,
    do: GenServer.call(__MODULE__, {:register_player, self()})

  def apply_answer(player_id, answer),
    do: GenServer.call(__MODULE__, {:apply_answer, player_id, answer})

  @impl true
  def init(room) do
    {:ok, room}
  end

  @impl true
  def handle_call({:register_player, pid}, _from, state) do
    {:ok, player_id, new_state} = Room.register_player(state, pid)

    case {Room.get_status(state), Room.get_status(new_state)} do
      {:stopped, :in_progress} ->
        inform_of_turn(new_state)

      _ ->
        :ok
    end

    {:reply, player_id, new_state}
  end

  @impl true
  def handle_call({:apply_answer, player_id, answer}, _from, state) do
    Process.send_after(self(), :answer_timeout, @answer_timeout)

    case Room.apply_answer(state, player_id, answer) do
      {result, new_room} ->
        inform_of_turn(new_room)
        inform_of_answer(new_room, player_id, answer)
        maybe_inform_of_lost(new_room, result, player_id)
        maybe_inform_of_won(new_room)
        {:reply, result, new_room}

      :ignore ->
        {:reply, :ignore, state}
    end
  end

  @impl true
  def handle_info(:answer_timeout, state) do
    case Room.get_current_player(state) do
      :no_players ->
        {:noreply, state}

      player ->
        inform_of_lost(state, player.id)
        new_room = Room.kick_out_player(state, player.id)
        {:noreply, new_room}
    end
  end

  defp inform_of_turn(room) do
    case Room.get_current_player(room) do
      :no_players ->
        :ok

      %{pid: pid} ->
        send(pid, :turn)
    end
  end

  defp inform_of_answer(room, player_id, answer) do
    room
    |> Room.get_players()
    |> Enum.filter(&(&1.id != player_id))
    |> Enum.each(&Kernel.send(&1.pid, {:answer, player_id, answer}))
  end

  defp maybe_inform_of_lost(room, :incorrect, player_id),
    do: inform_of_lost(room, player_id)

  defp maybe_inform_of_lost(_room, _, _player_id),
    do: :ok

  # TODO extract common code
  defp inform_of_lost(room, player_id) do
    room
    |> Room.get_players()
    |> Enum.filter(&(&1.id != player_id))
    |> Enum.each(&Kernel.send(&1.pid, {:lost, player_id}))
  end

  defp maybe_inform_of_won(room) do
    case Room.get_winner(room) do
      {:ok, winner} ->
        send(winner.pid, :won)

      :no_winner ->
        :ok
    end
  end
end
