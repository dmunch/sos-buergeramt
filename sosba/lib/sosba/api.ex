require Amnesia
require Database

use Amnesia
use Database

defmodule Sosba.Api do  
  use Maru.Router

  def load_users do
     (Amnesia.transaction do: User.where activated == false and matched == false, select: {id, name}).values
     |> Enum.map(fn u -> 
      {id, name} = u
      %{id: id, name: name}
     end)  
     
     #the following works but is very slow, we better not use it on many items
     #(Amnesia.transaction do: User.where ack == false)
     #|> Amnesia.Selection.values 
  end

  def create_user(params) do
      Amnesia.transaction do: User.create(params[:name], params[:email], params[:phone])
  end

  namespace :users do  
    desc "get all users" 
       get do: conn |> json load_users 
    
    desc "create a new user"
    params do 
      requires :name
      requires :email
      requires :phone
    end
    post do
      conn 
      |> put_status(201)
      |> json create_user(params) 
    end
  end
end  
