defmodule RoomUtils do

  # def userBelongsToRoom(user,room) do
  #   users = String.split(room,"_")
  #   with true <- (users[0] == user || users[1] == user)
  #   do
  #     true
  #   else _error ->
  #      false
  #   end
  # end

  # def roomId(userId1, userId2) do
  #   case userId1 < userId2 do
  #     true ->
  #       Base.encode64(:crypto.hash(:sha256,userId1 <> userId2))
  #     false ->
  #       Base.encode64(:crypto.hash(:sha256, userId2 <> userId1))
  #   end
  # end

end
