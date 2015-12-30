defmodule Scraper do
  use Timex 
  @base_url "https://service.berlin.de/terminvereinbarung/termin/"
  @url_booking "https://service.berlin.de/terminvereinbarung/termin/bestaetigung.php"
  @baseDaysDecember2015 1448924400

  @baseUrlDate "https://service.berlin.de/terminvereinbarung/termin/tag.php?id=&buergerID=&buergername=&absagecode=&Datum={date}&anliegen%5B%5D=120703&dienstleister%5B%5D=122210&dienstleister%5B%5D=122217&dienstleister%5B%5D=122219&dienstleister%5B%5D=122227&dienstleister%5B%5D=122231&dienstleister%5B%5D=122238&dienstleister%5B%5D=122243&dienstleister%5B%5D=122252&dienstleister%5B%5D=122260&dienstleister%5B%5D=122262&dienstleister%5B%5D=122254&dienstleister%5B%5D=122271&dienstleister%5B%5D=122273&dienstleister%5B%5D=122277&dienstleister%5B%5D=122280&dienstleister%5B%5D=122282&dienstleister%5B%5D=122284&dienstleister%5B%5D=122291&dienstleister%5B%5D=122285&dienstleister%5B%5D=122286&dienstleister%5B%5D=122296&dienstleister%5B%5D=150230&dienstleister%5B%5D=122301&dienstleister%5B%5D=122297&dienstleister%5B%5D=122294&dienstleister%5B%5D=122312&dienstleister%5B%5D=122314&dienstleister%5B%5D=122304&dienstleister%5B%5D=122311&dienstleister%5B%5D=122309&dienstleister%5B%5D=317869&dienstleister%5B%5D=324433&dienstleister%5B%5D=325341&dienstleister%5B%5D=324434&dienstleister%5B%5D=324435&dienstleister%5B%5D=122281&dienstleister%5B%5D=324414&dienstleister%5B%5D=122283&dienstleister%5B%5D=122279&dienstleister%5B%5D=122276&dienstleister%5B%5D=122274&dienstleister%5B%5D=122267&dienstleister%5B%5D=122246&dienstleister%5B%5D=122251&dienstleister%5B%5D=122257&dienstleister%5B%5D=122208&dienstleister%5B%5D=122226&herkunft=/terminvereinbarung/"
 
  def load_base do 
    load_for_date(@url, {2015, 12, 1})
  end
 
  def load_for_date(date, cache_control) do
    days = @baseDaysDecember2015 + Date.diff(Date.from({2015,12,1}), Date.from(date), :secs)

    url = String.replace(@baseUrlDate, "{date}", Integer.to_string(days))
    load(url, cache_control)
  end

  def load(url, cache_control \\ "", cookie \\ "") do 
    load_response(url, cache_control, cookie).body
  end

  def load_response(url, cache_control \\ "", cookie \\ "") do 
    options = [proxy: "localhost:8118", recv_timeout: 80000, timeout: 80000]

    #we optionally add an additional query parameter so that we're sure to bypass the varnish cache 
    case cache_control do
      "" -> url = url
      _ -> url = url <> "&cc=#{cache_control}" 
    end
    case cookie do
      "" -> options = options 
      _ -> options = options ++ [hackney: [cookie: [{"ZMS-BO_Webinterface", cookie}]]]
    end
    
    #brute force, in case of any error we just retry until we succeed
    case HTTPoison.get url, %{}, options do
      {:ok, resp} -> resp
      _ -> load_response(url, cache_control, cookie)
    end
  end

  def get_auth_cookie do
    url = "https://service.berlin.de/terminvereinbarung/termin/blank.png"
    cookie = load_response(url) 
    |>(fn r -> r.headers end).()
    |> Enum.find(fn h -> {key, _} = h; key == "Set-Cookie" end)
    #should result in {"Set-Cookie", "ZMS-BO_Webinterface=r0t8hqq74d0ck80pca6lsvadk0; path=/"}
    
    #match and extract the cookie value
    {key, value} = cookie
    value
    |> String.split(";")
    |> hd 
    |> String.split("=")
    |> tl   
  end

  def parse_two_months(html) do  
    html
    |> Floki.find(".calendar-month-table") 
    |> Enum.map(&parse_month_table/1)
  end

  def parse_german_month_year(month_year_list) do
    {month, year} = case month_year_list do
      ["Januar", year] -> {1, year}
      ["Februar", year] -> {2, year}
      ["März", year] -> {3, year}
      ["April", year] -> {4, year}
      ["Mai", year] -> {5, year}
      ["Juni", year] -> {6, year}
      ["Juli", year] -> {7, year}
      ["August", year] -> {8, year}
      ["September", year] -> {9, year}
      ["Oktober", year] -> {10, year}
      ["November", year] -> {11, year}
      ["Dezember", year] -> {12, year}
    end

    {year, _} = Integer.parse(year)
    {month, year}
  end

  def parse_month_table(month_table) do
    {month, year} = month_table 
    |> Floki.find(".month")
    |> Floki.text
    |> String.strip
    |> String.split(" ")
    |> parse_german_month_year


    bookable = month_table 
    |> Floki.find(".buchbar")
    |> Enum.map(fn td -> 
          {day, _} = td |> Floki.text |> Integer.parse
          %{date: {year, month, day}, url: Floki.find(td, "a") |> Floki.attribute("href") |> hd} 
        end
      )

    bookable
  end

  def run do
    cache_control = :os.system_time()
    Date.now |> DateFormat.format("{YYYY}-{M}-{D}-{h24}-{m}-{s}")

    dates = [
      {2015, 12, 1},
      {2016,  2, 1}
    ]
    |> Enum.map(&Task.async(fn -> load_for_date(&1, cache_control) end))
    |> Enum.map(&Task.await(&1, 20000))
    |> Enum.map(&parse_two_months/1)
    |> Enum.reduce([], fn(x, acc) -> acc ++ x end)
    |> List.flatten
    
    
    #dates |> inspect |> IO.puts

    cookie = get_auth_cookie
    process_timetable = fn(date) -> 
      cookie = get_auth_cookie
      load(@base_url <> date.url, cache_control, cookie)
      |> save_timetable(date)
      |> parse_timetable
      |> List.flatten
      |> Enum.map(&Dict.put(&1, :date, date.date))
      |> Enum.map(&Dict.put(&1, :cookie, cookie))
    end

    appointements = dates 
    |> Enum.map(fn date -> Task.async(fn -> process_timetable.(date) end) end) 
    |> Enum.map(&Task.await(&1, 80000))
    |> List.flatten

    #appointements
    #|> Enum.map(&inspect/1)
    #|> Enum.map(&IO.puts/1)

    File.write! "appointements.bin", :erlang.term_to_binary(appointements)
    appointements
  end

  def save_timetable(html, date) do
    {year, month, day} = date.date
    file_name = "#{day}-#{month}-#{year}.html"
    {:ok, file} = File.open file_name, [:write]
    IO.binwrite file, html
    File.close file 
    
    IO.puts file_name
    html
  end

  def parse_timetable(html) do
    html
    |> Floki.find(".timetable tr")
    |> Enum.map fn row ->
      row 
          |> Floki.find("a") 
          |> Enum.map fn of -> 
            url = of |> Floki.attribute("href") |> hd
            %{
              time: url |> parse_zeit,
              oid: url |> parse_oid,
              anliegen: url |> parse_anliegen,
              url: @base_url <> url, 
              name: of |> Floki.text
            }
          end
    end
  end

  def parse_oid(url) do url |> parse_query_string("OID") end
  def parse_anliegen(url) do url |> parse_query_string("anliegen[]") end
  def parse_zeit(url) do url |> parse_query_string("zeit") end
  def parse_query_string(url, field) do
    url
    |> URI.decode_query 
    |> (fn map -> map[field] end).() 
  end

  def book_appointement(appt) do
    form = load(appt.url, "", appt.cookie)
    |> parse_appointement_page
    |> Dict.put(:EMail, "coun1932@gustr.com")
    |> Dict.put(:Nachname, "siggi")   
    #telefonnummer_fuer_rueckfragen 
    
    HTTPoison.post(@url_booking, {:form, form},  
                   %{"Content-type" => "application/x-www-form-urlencoded", "Accept" => "text/html"},  
                   [hackney: [cookie: [{"ZMS-BO_Webinterface", appt.cookie}]]])       
  end
  
  def parse_appointement_page(html) do
    html  
    |> Floki.find("form")
    |> Enum.at(1) 
    |> Floki.find("input")
    |> Enum.filter(&Floki.attribute(&1, "type") |> hd != "submit")
    |> Enum.map(&%{name: Floki.attribute(&1, "name") |> hd, value: Floki.attribute(&1, "value") |> hd })
    |> Enum.reduce([], fn(x, acc) -> Dict.put(acc, String.to_atom(x.name), x.value) end) 
  end
end
