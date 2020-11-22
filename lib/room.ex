defmodule CasksBarrels.Room do
  @min_players 2

  defmodule Player do
    defstruct [:id, :pid]
  end

  defstruct players: [],
            current_player_index: 0,
            game_state: 0,
            status: :stopped,
            winner: :not_set

  def new, do: %__MODULE__{}

  def register_player(room, pid) do
    player = %Player{id: UUID.uuid4(), pid: pid}

    new_room =
      room
      |> Map.update!(:players, &(&1 ++ [player]))
      |> update_status(:player_registered)

    {:ok, player.id, new_room}
  end

  def kick_out_player(room, player_id) do
    new_players_length = length(room.players) - 1

    adjust_current_player = fn index ->
      case index do
        0 -> 0
        _ -> rem(index, new_players_length)
      end
    end

    new_room =
      room
      |> Map.update!(:players, fn players -> Enum.filter(players, &(&1.id != player_id)) end)
      |> Map.update!(:current_player_index, adjust_current_player)
      |> update_status(:player_kicked)

    new_room
  end

  def get_status(room), do: room.status

  defp update_status(room, :player_registered) do
    if length(room.players) >= @min_players do
      room
      |> Map.put(:status, :in_progress)
      |> Map.put(:winner, :not_set)
      |> Map.put(:game_state, 0)
    else
      room
    end
  end

  defp update_status(room, :player_kicked) do
    case room.players do
      [winner] ->
        room
        |> Map.put(:status, :stopped)
        |> Map.put(:winner, winner)

      _ ->
        room
    end
  end

  def game_started?(room), do: length(room.players) >= @min_players

  def get_current_player(room) do
    Enum.at(room.players, room.current_player_index, :no_players)
  end

  def get_players(room), do: room.players

  def apply_answer(room, player_id, answer) do
    with :in_progress <- room.status,
         %Player{id: ^player_id} <- get_current_player(room),
         {:correct?, true} <- {:correct?, answer_correct?(room.game_state + 1, answer)} do
      new_room =
        room
        |> Map.update!(:game_state, &(&1 + 1))
        |> next_turn()

      {:correct, new_room}
    else
      {:correct?, false} ->
        new_room = kick_out_player(room, player_id)
        {:incorrect, new_room}

      _ ->
        :ignore
    end
  end

  def get_winner(room) do
    case room.winner do
      :not_set -> :no_winner
      _ -> {:ok, room.winner}
    end
  end

  defp answer_correct?(value, :barrels_and_casks), do: rem(value, 5) == 0 and rem(value, 7) == 0
  defp answer_correct?(value, :casks), do: rem(value, 5) == 0
  defp answer_correct?(value, :barrels), do: rem(value, 7) == 0

  defp answer_correct?(value, value) when is_integer(value),
    do: rem(value, 5) != 0 and rem(value, 7) != 0

  defp answer_correct?(_value, _answer), do: false

  defp next_turn(room) do
    case room.players do
      [] ->
        %{room | current_player_index: 0}

      _ ->
        next = rem(room.current_player_index + 1, length(room.players))
        %{room | current_player_index: next}
    end
  end
end
