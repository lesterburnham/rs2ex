defmodule RS2.Interface.Button do
  require Logger

  @emotes %{
    161 => 860,
    162 => 857,
    163 => 863,
    164 => 858,
    165 => 859,
    166 => 866,
    167 => 864,
    168 => 855,
    169 => 856,
    170 => 861,
    171 => 862,
    172 => 865,
    13_362 => 2105,
    13_363 => 2106,
    13_364 => 2107,
    13_365 => 2108,
    13_366 => 2109,
    13_367 => 2110,
    13_368 => 2111,
    13_383 => 2127,
    13_384 => 2128,
    13_369 => 2112,
    13_370 => 2113,
    11_100 => 1368,
    667 => 1131,
    6503 => 1130,
    6506 => 1129,
    666 => 1128
  }

  # emotes
  def handle_click(_session, button_id) when is_map_key(@emotes, button_id) do
    animation = Map.get(@emotes, button_id)
    Logger.info("animation: #{animation}")
  end

  def handle_click(_session, button_id) do
    # {button_id}
    Logger.info("unhandled button: #{button_id}")
  end
end
