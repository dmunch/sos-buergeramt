defmodule Scraper do
  
    @url "https://service.berlin.de/terminvereinbarung/termin/tag.php?termin=1&dienstleister%5B%5D=122210&dienstleister%5B%5D=122217&dienstleister%5B%5D=122219&dienstleister%5B%5D=122227&dienstleister%5B%5D=122231&dienstleister%5B%5D=122238&dienstleister%5B%5D=122243&dienstleister%5B%5D=122252&dienstleister%5B%5D=122260&dienstleister%5B%5D=122262&dienstleister%5B%5D=122254&dienstleister%5B%5D=122271&dienstleister%5B%5D=122273&dienstleister%5B%5D=122277&dienstleister%5B%5D=122280&dienstleister%5B%5D=122282&dienstleister%5B%5D=122284&dienstleister%5B%5D=122291&dienstleister%5B%5D=122285&dienstleister%5B%5D=122286&dienstleister%5B%5D=122296&dienstleister%5B%5D=150230&dienstleister%5B%5D=122301&dienstleister%5B%5D=122297&dienstleister%5B%5D=122294&dienstleister%5B%5D=122312&dienstleister%5B%5D=122314&dienstleister%5B%5D=122304&dienstleister%5B%5D=122311&dienstleister%5B%5D=122309&dienstleister%5B%5D=317869&dienstleister%5B%5D=324433&dienstleister%5B%5D=325341&dienstleister%5B%5D=324434&dienstleister%5B%5D=324435&dienstleister%5B%5D=122281&dienstleister%5B%5D=324414&dienstleister%5B%5D=122283&dienstleister%5B%5D=122279&dienstleister%5B%5D=122276&dienstleister%5B%5D=122274&dienstleister%5B%5D=122267&dienstleister%5B%5D=122246&dienstleister%5B%5D=122251&dienstleister%5B%5D=122257&dienstleister%5B%5D=122208&dienstleister%5B%5D=122226&anliegen%5B%5D=120703&herkunft=%2Fterminvereinbarung%2F"
 
  @urlAppointement "https://service.berlin.de/terminvereinbarung/termin/termin.php?buergerID=&buergername=&OID=68985%2C69009%2C69033%2C78484%2C78496%2C62128%2C61603%2C62113%2C62143%2C68184%2C68154%2C68214%2C78424%2C54118%2C54120%2C78436%2C78442%2C74224%2C78295%2C78397%2C74992%2C37495%2C74701%2C75442%2C64687%2C71508%2C40769%2C77842%2C76162%2C54419%2C54411%2C76810%2C77605%2C77608%2C77611%2C77536%2C77539%2C77353%2C77362%2C77371%2C66153%2C66159%2C66165%2C65277%2C65283%2C65289&datum=2016-02-17&behoerde=&slots=&anliegen%5B%5D=120703&dienstleister%5B%5D=122210&dienstleister%5B%5D=122217&dienstleister%5B%5D=122219&dienstleister%5B%5D=122227&dienstleister%5B%5D=122231&dienstleister%5B%5D=122238&dienstleister%5B%5D=122243&dienstleister%5B%5D=122252&dienstleister%5B%5D=122260&dienstleister%5B%5D=122262&dienstleister%5B%5D=122254&dienstleister%5B%5D=122271&dienstleister%5B%5D=122273&dienstleister%5B%5D=122277&dienstleister%5B%5D=122280&dienstleister%5B%5D=122282&dienstleister%5B%5D=122284&dienstleister%5B%5D=122291&dienstleister%5B%5D=122285&dienstleister%5B%5D=122286&dienstleister%5B%5D=122296&dienstleister%5B%5D=150230&dienstleister%5B%5D=122301&dienstleister%5B%5D=122297&dienstleister%5B%5D=122294&dienstleister%5B%5D=122312&dienstleister%5B%5D=122314&dienstleister%5B%5D=122304&dienstleister%5B%5D=122311&dienstleister%5B%5D=122309&dienstleister%5B%5D=317869&dienstleister%5B%5D=324433&dienstleister%5B%5D=325341&dienstleister%5B%5D=324434&dienstleister%5B%5D=324435&dienstleister%5B%5D=122281&dienstleister%5B%5D=324414&dienstleister%5B%5D=122283&dienstleister%5B%5D=122279&dienstleister%5B%5D=122276&dienstleister%5B%5D=122274&dienstleister%5B%5D=122267&dienstleister%5B%5D=122246&dienstleister%5B%5D=122251&dienstleister%5B%5D=122257&dienstleister%5B%5D=122208&dienstleister%5B%5D=122226&herkunft=%2Fterminvereinbarung%2F"

  def load_base do 
    load(@url)
  end
  
  def load_app do 
    load(@urlAppointement)
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

  def parse(html) do  
    html
    |> Floki.find(".calendar-month-table") 
    |> Enum.map(&parse_month_table/1)
  end

  def parse_month_table(month_table) do
    month = month_table 
    |> Floki.find(".month")
    |> Floki.text

    bookable = month_table 
    |> Floki.find(".buchbar")
    |> Enum.map(fn td -> %{day: Floki.text(td), url: Floki.find(td, "a") |> Floki.attribute("href")} end)

    unbookable = month_table 
    |> Floki.find(".nichtbuchbar")
    |> Enum.map(&Floki.text/1)

    #%{month: month, bookable: bookable, unbookable: unbookable}
    %{month: month, bookable: bookable}
  end

  def parse_next_month_url(html) do
    base_url = "https://service.berlin.de/terminvereinbarung/termin/"

    #there's always two links to the next month, the one right next to the name of the month
    #and another one further down. we're only interested in the later, hence we only use
    #the tail of the list. In case of only one element being found, tl returns an empty list and we know 
    #that we have to stop.
    case Floki.find(html, "a[title^=nä]") |> tl do
      [el] -> {:ok, base_url <> (Floki.attribute(el, "href") |> hd)}
      [] -> {:none}
    end
  end

  def parse_and_follow(url, cache_control) do
    html = load(url, cache_control)
    months = parse(html)
    case parse_next_month_url(html) do
      {:ok, url} -> (months ++ parse_and_follow(url, cache_control)) |> Enum.uniq_by(fn a -> a.month end)
      {:none} -> months
    end
  end
  
  def run do
    parse_and_follow(@url, :os.system_time())
  end
end
