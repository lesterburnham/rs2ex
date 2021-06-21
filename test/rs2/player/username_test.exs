defmodule RS2.Player.UsernameTest do
  use ExUnit.Case
  alias RS2.Player.Username

  test "long to name" do
    assert Username.long_to_name(25_145_847) == "mopar"
    assert Username.long_to_name(33_768) == "xxx"
    assert Username.long_to_name(4_388_550_766_608_586_082) == "xxx_1337_xxx"
    assert Username.long_to_name(6_582_952_005_840_035_280) == "999999999999"
    assert Username.long_to_name(8_454_104_187_155) == "bob_saget"
    assert Username.long_to_name(1_557_660) == "3027"
  end

  test "name to long" do
    assert Username.name_to_long("mopar") == 25_145_847
    assert Username.name_to_long("Mopar") == 25_145_847
    assert Username.name_to_long("bob_saget") == 8_454_104_187_155
    assert Username.name_to_long("xxx_1337_xxx") == 4_388_550_766_608_586_082

    # strip trailing underscores
    assert Username.name_to_long("mopar_") == Username.name_to_long("mopar")
    assert Username.name_to_long("mopar__") == Username.name_to_long("mopar")
  end

  test "format name for protocol" do
    assert Username.format_name_protocol("Bob Saget") == "bob_saget"
    assert Username.format_name_protocol("Mopar123") == "mopar123"
  end

  test "valid name" do
    assert Username.valid_name?("bob_saget32") == true
    assert Username.valid_name?("Bob") == false
    assert Username.valid_name?("bob!") == false
  end

  test "fix name" do
    assert Username.fix_name("bob_saget") == "Bob Saget"
  end

  test "format name" do
    assert Username.format_name("bob_saget") == "Bob_Saget"
  end
end
