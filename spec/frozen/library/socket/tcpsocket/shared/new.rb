require File.expand_path('../../../../../spec_helper', __FILE__)
require File.expand_path('../../../fixtures/classes', __FILE__)

describe :tcpsocket_new, :shared => true do
  before :all do
    SocketSpecs::SpecTCPServer.start
  end

  after :all do
    SocketSpecs::SpecTCPServer.cleanup
  end

  before :each do
    @hostname = SocketSpecs::SpecTCPServer.get.hostname
  end

  it "requires a hostname and a port as arguments" do
    lambda { TCPSocket.send(@method) }.should raise_error(ArgumentError)
  end

  it "throws a type error if the port is not a fixnum or string" do
    lambda { TCPSocket.send(@method, @hostname, {}) }.should raise_error(TypeError)
  end

  it "refuses the connection when there is no server to connect to" do
    lambda do
      TCPSocket.send(@method, @hostname, SocketSpecs.local_port)
    end.should raise_error(Errno::ECONNREFUSED)
  end

  describe "with a running server" do
    before :each do
      @socket = nil
    end

    after :each do
      if @socket
        @socket.write "QUIT"
        @socket.shutdown
        @socket.close
      end
    end

    it "silently ignores 'nil' as the third parameter" do
      @socket = TCPSocket.send(@method, @hostname, SocketSpecs.port, nil)
      @socket.should be_an_instance_of(TCPSocket)
    end

    it "connects to a listening server with host and port" do
      @socket = TCPSocket.send(@method, @hostname, SocketSpecs.port)
      @socket.should be_an_instance_of(TCPSocket)
    end

    it "connects to a server when passed local_host argument" do
      @socket = TCPSocket.send(@method, @hostname, SocketSpecs.port, @hostname)
      @socket.should be_an_instance_of(TCPSocket)
    end

    it "connects to a server when passed local_host and local_port arguments" do
      @socket = TCPSocket.send(@method, @hostname, SocketSpecs.port,
                               @hostname, SocketSpecs.local_port)
      @socket.should be_an_instance_of(TCPSocket)
    end

    it "has an address once it has connected to a listening server" do
      @socket = TCPSocket.send(@method, @hostname, SocketSpecs.port)
      @socket.should be_an_instance_of(TCPSocket)

      # TODO: Figure out how to abstract this. You can get AF_INET
      # from 'Socket.getaddrinfo(hostname, nil)[0][3]' but socket.addr
      # will return AF_INET6. At least this check will weed out clearly
      # erroneous values.
      @socket.addr[0].should =~ /^AF_INET6?/

      case @socket.addr[0]
      when 'AF_INET'
        @socket.addr[3].should == SocketSpecs.addr(:ipv4)
      when 'AF_INET6'
        @socket.addr[3].should == SocketSpecs.addr(:ipv6)
      end

      @socket.addr[1].should be_kind_of(Fixnum)
      @socket.addr[2].should =~ /^#{@hostname}/
    end
  end
end
