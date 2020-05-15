defmodule Identicon do
  @moduledoc """
    This module exposes a function `create_identicon` which receives a string as an argument and
    produces an identicon from it, then saves it under the `saved_identicons` local file
  """

  @doc """
    This is the main and only function exposed by this module, which contains all the logic to create an
    identicon from a string
  """
  def create_identicon(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Receives a string as an argument and produces an integer list with the string's representation
    stored in the Identicon.Image structur
  """
  defp hash_input(input) do
    # I use erlang's crypto and binary library to obtain a representation of our string in a list of numbers
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    # I use the Identicon.Image struct to store the value
    %Identicon.Image{hex: hex}
  end

  @doc """
    Receives an Identicon.Image structure with the hex list created and generates a tuple with the
    RGB color representation and stores it in the structure
  """
  defp pick_color(%Identicon.Image{hex: [red, green, blue | _tail]} = image) do
    %Identicon.Image{image | color: {red, green, blue}}
  end

  @doc """
    Receives an Identicon.Image structure with the hex list created and generates
    a grid with the necessary data to draw the identicon
  """
  defp build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> List.delete_at(length(hex) - 1)
      |> Enum.chunk_every(3)
      # & passes the reference of the function
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      # Produces a list of size 2 tuples with the value plus an added index
      |> Enum.with_index()

    %Identicon.Image{image | grid: grid}
  end

  @doc """
    Receives Identicon.Image structure and determines whether each cell should be colored
  """
  defp filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    filtered_grid =
      grid
      |> Enum.filter(fn {code, _} ->
        rem(code, 2) == 0
      end)

    %Identicon.Image{image | grid: filtered_grid}
  end

  @doc """
    Receives Identicon.Image structure with a generated grid and produces a pixel map for the final step
    of drawing the identicon
  """
  defp build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      grid
      |> Enum.map(fn {_code, index} ->
        horizontal = rem(index, 5) * 50
        vertical = div(index, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        {top_left, bottom_right}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """
    Receives the Identicon.Image structure, extracts it's pixel map
    and uses :egd (erlang graphical drawer) to draw the image
  """
  defp draw_image(%Identicon.Image{pixel_map: pixel_map, color: color}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  @doc """
    Receives the generated identicon as an image, and the initial string to save the image
    into the `saved_identicons` folder
  """
  defp save_image(image, input) do
    File.write("./saved_identicons/#{input}.png", image)
  end

  @doc """
    Helper function used in the logic of the grid building in order to make a mirrored grid
  """
  defp mirror_row(row) do
    [first, second | _tail] = row
    row ++ [second, first]
  end
end
