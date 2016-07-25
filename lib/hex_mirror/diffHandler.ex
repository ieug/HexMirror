defmodule HexMirror.DiffHandler do
    use GenServer
	
    @hexmirror_home "/home/yohanes/hexProject/HexMirror"
    @oldregistry "oldregistry"
    @newregistry "registry"

    def start_link(name) do
	GenServer.start_link(__MODULE__, :ok, name: name)
    end

    def handle_diff(server) do
	GenServer.cast(server, {:handlediff})  
    end

  
    def init(:ok) do 
	{:ok, {}}
    end

    def handle_cast({:handlediff}, state) do 
	IO.puts "Starting diffing"
	extract()
	
        if File.exists?(Path.join(@hexmirror_home, @oldregistry)) do
	    {:ok, newtid} = :ets.file2tab(String.to_atom(Path.join(@hexmirror_home, @newregistry)))
	    {:ok, oldtid} = :ets.file2tab(String.to_atom(Path.join(@hexmirror_home, @oldregistry)))

	    diffMap = diff(newtid, oldtid)
	    
            case MapSet.size(diffMap) do
	        0 ->
		  IO.puts "The registry is up-to-date"
		_ ->
		  IO.puts "The following packages are not syched:"
		  IO.inspect MapSet.to_list(diffMap)
	    end			
	    ##DELETE OLD AT LAST
	end

	{:noreply, state}
    end
	
    defp diff(old, new) do
        a = collect(old)
  	b = collect(new)

  	MapSet.difference(a, b)
    end

    defp collect(tid) do
  	fun = fn
    	    {{package, version}, _}, acc
              when is_binary(package) and is_binary(version) ->
      	          [{package, version}] ++ acc
    	      _, acc ->
     		  acc
  	    end

  	:ets.foldl(fun, [], tid)
  	    |> Enum.into(MapSet.new)
    end
	
    defp extract do
        IO.puts "Extracting..."
	
        path = Path.join(@hexmirror_home, @newregistry)
	
        if File.exists?(path) do
	    File.rename(path, Path.join(@hexmirror_home, @oldregistry))
	end

	{:ok, data} = File.read(Path.join(@hexmirror_home, "registry.ets.gz"))
	unzipped = :zlib.gunzip(data)
	File.write!(path, unzipped)		 
    end
		
end
