defmodule RS2.Container.Item.Definition do
  @enforce_keys [:id]

  @properties [
    :id,
    :name,
    :parent,
    :noteID,
    :basevalue,
    :att_stab_bonus,
    :att_slash_bonus,
    :att_crush_bonus,
    :att_magic_bonus,
    :att_ranged_bonus,
    :def_stab_bonus,
    :def_slash_bonus,
    :def_crush_bonus,
    :def_magic_bonus,
    :def_ranged_bonus,
    :strength_bonus,
    :prayer_bonus,
    :weight
  ]

  @boolean_properties [:noted, :noteable, :stackable, :members, :prices]

  defstruct @properties ++ @boolean_properties

  def high_alc(%__MODULE__{basevalue: basevalue}) do
    (0.6 * basevalue) |> round
  end

  def low_alc(%__MODULE__{basevalue: basevalue}) do
    (0.4 * basevalue) |> round
  end

  def for_id(id) do
    # ------
    # todo: cache this at some point
    {:ok, conn} = Exqlite.Sqlite3.open("./priv/item_definitions.db")

    keys = @properties ++ @boolean_properties

    property_list = keys |> Enum.join(", ")

    {:ok, statement} =
      Exqlite.Sqlite3.prepare(conn, "select #{property_list} from items where id = ?1")

    :ok = Exqlite.Sqlite3.bind(conn, statement, [id])

    {:row, r} = Exqlite.Sqlite3.step(conn, statement)

    Exqlite.Sqlite3.close(conn)
    # ------

    Enum.zip(keys, r)
    |> Enum.into(%{})
    |> Enum.map(fn {k, v} ->
      if Enum.member?(@boolean_properties, k) do
        {k, if(v == 1, do: true, else: false)}
      else
        {k, v}
      end
    end)
    |> then(&struct(%__MODULE__{id: id}, &1))
  end
end
