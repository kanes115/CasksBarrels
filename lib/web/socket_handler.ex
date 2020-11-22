defmodule CasksBarrelsWeb.SocketHandler do
  @behaviour :cowboy_websocket

  @lost_msg {:text, "drink"}
  @won_msg {:text, "win"}
  @turn_msg {:text, "turn"}
  @out_of_turn_msg {:text, "Not your turn!"}

  alias CasksBarrels.RoomManager

  require Logger

  def init(request, state) do
    {:cowboy_websocket, request, state}
  end

  def websocket_init(_state) do
    state = %{my_id: RoomManager.register_player()}

    {:ok, state}
  end

  def websocket_handle({:text, message}, state) do
    case cast_message(message) do
      :error ->
        {:ok, state}

      game_input ->
        case RoomManager.apply_answer(state.my_id, game_input) do
          :correct ->
            {:ok, state}

          :incorrect ->
            send(self(), :stop)
            {:reply, @lost_msg, state}

          :ignore ->
            {:reply, @out_of_turn_msg, state}
        end
    end
  end

  def websocket_info(:turn, state) do
    {:reply, @turn_msg, state}
  end

  def websocket_info({:answer, player_id, answer}, state) do
    answer_str = dump_message(answer)
    response = "turn #{player_id} #{answer_str}"

    {:reply, {:text, response}, state}
  end

  def websocket_info({:lost, player_id}, state) do
    response = "lost #{player_id}"

    {:reply, {:text, response}, state}
  end

  def websocket_info(:won, state) do
    {:reply, @won_msg, state}
  end

  def websocket_info(:stop, state) do
    {:stop, state}
  end

  defp cast_message("barrels & casks"), do: :barrels_and_casks
  defp cast_message("barrels"), do: :barrels
  defp cast_message("casks"), do: :casks

  defp cast_message(n) do
    case Integer.parse(n) do
      {number, ""} -> number
      _ -> :error
    end
  end

  defp dump_message(:barrels_and_casks), do: "barrels & casks"
  defp dump_message(:barrels), do: "barrels"
  defp dump_message(:casks), do: "casks"
  defp dump_message(n) when is_integer(n), do: "#{n}"
end
