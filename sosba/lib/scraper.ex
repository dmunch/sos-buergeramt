defmodule Scraper do
  
    @url "https://service.berlin.de/terminvereinbarung/termin/tag.php?termin=1&dienstleister%5B%5D=122210&dienstleister%5B%5D=122217&dienstleister%5B%5D=122219&dienstleister%5B%5D=122227&dienstleister%5B%5D=122231&dienstleister%5B%5D=122238&dienstleister%5B%5D=122243&dienstleister%5B%5D=122252&dienstleister%5B%5D=122260&dienstleister%5B%5D=122262&dienstleister%5B%5D=122254&dienstleister%5B%5D=122271&dienstleister%5B%5D=122273&dienstleister%5B%5D=122277&dienstleister%5B%5D=122280&dienstleister%5B%5D=122282&dienstleister%5B%5D=122284&dienstleister%5B%5D=122291&dienstleister%5B%5D=122285&dienstleister%5B%5D=122286&dienstleister%5B%5D=122296&dienstleister%5B%5D=150230&dienstleister%5B%5D=122301&dienstleister%5B%5D=122297&dienstleister%5B%5D=122294&dienstleister%5B%5D=122312&dienstleister%5B%5D=122314&dienstleister%5B%5D=122304&dienstleister%5B%5D=122311&dienstleister%5B%5D=122309&dienstleister%5B%5D=317869&dienstleister%5B%5D=324433&dienstleister%5B%5D=325341&dienstleister%5B%5D=324434&dienstleister%5B%5D=324435&dienstleister%5B%5D=122281&dienstleister%5B%5D=324414&dienstleister%5B%5D=122283&dienstleister%5B%5D=122279&dienstleister%5B%5D=122276&dienstleister%5B%5D=122274&dienstleister%5B%5D=122267&dienstleister%5B%5D=122246&dienstleister%5B%5D=122251&dienstleister%5B%5D=122257&dienstleister%5B%5D=122208&dienstleister%5B%5D=122226&anliegen%5B%5D=120703&herkunft=%2Fterminvereinbarung%2F"
  
  def load_base do 
    load(@url)
  end
  end
  
  def load(url) do 
    resp = HTTPoison.get! url
    resp.body 
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
    |> Enum.map(&Floki.text/1)

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

  def parse_and_follow(url) do
    html = load(url)
    months = parse(html)
    case parse_next_month_url(html) do
      {:ok, url} -> (months ++ parse_and_follow(url)) |> Enum.uniq_by(fn a -> a.month end)
      {:none} -> months
    end
  end
  
  def run do
  end

end
