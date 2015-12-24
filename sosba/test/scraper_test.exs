defmodule ScraperTest do
  use ExUnit.Case
  doctest Scraper

  test "should parse the timetable" do
    timetable = File.read!("test/timetable-17-2-2016.html")
    |> Scraper.parse_timetable
  
    assert (timetable |> hd |> hd) == %{
      time: "11:15",
      name: "Bürgeramt Reinickendorf-Ost, Reinickendorf",
      oid: "64687",
      anliegen: "120703"
    }
  end

  test "should parse the OID" do
    oid =  "eintragen.php?buergerID=&buergername=&OID=64687&OIDListe=68985,69009,69033,78484"
    |> Scraper.parse_oid
    
    assert oid == "64687"
  end
  
  test "should parse the anliegen" do
    anliegen =  "eintragen.php?buergerID=&OIDListe=78484&slots=&anliegen%5B%5D=120703&dienstleister%5B%5D=122210&"
    |> Scraper.parse_anliegen
    
    assert anliegen == "120703"
  end
end
