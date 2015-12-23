defmodule Scraper do
  use Timex 
  @base_url "https://service.berlin.de/terminvereinbarung/termin/"
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

  def load(url, cache_control, cookie) do
    #we add an additional query parameter so that we're sure to bypass the varnish cache 
    url = url <> "&cc=#{cache_control}"
    
    #brute force, in case of any error we just retry until we succeed
    case HTTPoison.get url, %{}, hackney: [cookie: [{"ZMS-BO_Webinterface", cookie}]]
    do
      {:ok, resp} -> resp.body
      _ -> load(url, cache_control, cookie)
    end
  end
  
  def load(url, cache_control) do
    #we add an additional query parameter so that we're sure to bypass the varnish cache 
    load(url <> "&cc=#{cache_control}")
  end
  
  def load(url) do 
    #brute force, in case of any error we just retry until we succeed
    case HTTPoison.get url do
      {:ok, resp} -> resp.body
      _ -> load(url)
    end
  end

  def get_auth_cookie do
    cookie = (HTTPoison.get! "https://service.berlin.de/terminvereinbarung/termin/blank.png")
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
    
    #and can be used like follows:
    #HTTPoison.get url , %{}, hackney: [cookie: [{"ZMS-BO_Webinterface", "88880a0dio4qdiqv54u8tj1004"}]]
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
    
    #dates1 = load_for_date({2015, 12, 1}, cache_control) |> parse_two_months
    dates2 = load_for_date({2016,  1, 1}, cache_control) |> parse_two_months
    
    #dates = (dates1 ++ dates2) |> List.flatten
    dates = dates2 |> List.flatten
    
    cookie = get_auth_cookie
    
    dates |> inspect |> IO.puts

    dates
    |> Enum.map(fn d -> %{date: d.date, html: load(@base_url <> d.url, cache_control, cookie)} end)
    |> Enum.map(fn d ->
      {year, month, day} = d.date
      file_name = "#{day}-#{month}-#{year}.html"
      {:ok, file} = File.open file_name, [:write]
      IO.binwrite file, d.html
      File.close file 
      
      file_name
    end)
  end
end
