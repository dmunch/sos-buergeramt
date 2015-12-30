use Amnesia

defdatabase Database do
  deftable User, [{ :id, autoincrement }, :name, :email, :phone, :activated, :time_registered, :time_activated, :matched, :time_matched], type: :ordered_set, index: [:email] do
    
    @type t :: %User{
        id: non_neg_integer, 
        name: String.t, 
        email: String.t,
        phone: String.t,
        activated: Boolean.t,
        time_registered: non_neg_integer,
        time_activated: non_neg_integer,
        matched: Boolean.t,
        time_matched: non_neg_integer
    }

    def create(name, email, phone) do
      %User{
        name: name,
        email: email, 
        phone: phone,
        activated: false,
        time_registered: 0, 
        time_activated: 0, 
        matched: false,
        time_matched: 0 
      } |> write
    end

    def activate(self) do
      self |> Dict.put(:ack, true) |> write
    end
  end
end
