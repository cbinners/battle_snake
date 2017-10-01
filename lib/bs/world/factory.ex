defmodule Bs.World.Factory do
  alias Bs.Snake
  alias Bs.World

  @timeout 200
  @new_snake_length 3

  def build(game_form) do
    world = %World{
        game_form_id: game_form.id,
        height: game_form.height,
        max_food: game_form.max_food,
        snakes: [],
        width: game_form.width,
        game_id: game_form.id
      }

    snakes =
      game_form.snakes
      |> Task.async_stream(&(task &1, game_form), [timeout: @timeout])
      |> Enum.map(fn {:ok, snake} -> snake end)

    world = put_in world.snakes, snakes

    world = World.stock_food world

    update_in world.snakes, fn snakes ->
      for snake <- snakes do
        {:ok, point} = World.rand_unoccupied_space(world)

        coords = List.duplicate(point, @new_snake_length)

        put_in snake.coords, coords
      end
    end
  end

  def task snake_form, game_form do
    url = snake_form.url
    url = "#{url}/start"

    response = HTTPoison.post!(
      url,
      Poison.encode!(game_form),
      ["content-type": "application/json"],
      [recv_timeout: @timeout]
    )

    json = Poison.decode! response.body

    model = %Snake{
      url: snake_form.url,
      id: snake_form.id,
    }

    changeset = Snake.changeset(model, json)

    if changeset.valid? do
      Ecto.Changeset.apply_changes changeset
    else
      raise changeset.errors
    end
  end
end