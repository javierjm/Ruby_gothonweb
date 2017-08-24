require './bin/app.rb'
require "test/unit"
require "rack/test"


class TestGothonWeb < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  @rooms = [Map::START, Map::LASER_WEAPON_ARMORY, Map::THE_BRIDGE, Map::ESCAPE_POD, Map::THE_END_WINNER, Map::THE_END_LOSER]
  @actions = {Map::START =>'tell a joke', Map::LASER_WEAPON_ARMORY=>'0132',  Map::THE_BRIDGE=>'slowly place the bomb',Map::ESCAPE_POD=>'2'}


  def test_room()
    gold = Map::Room.new("GoldRoom",
      """This room has gold in it you can grab. There's alias_method 
      door to the north.""")
    assert_equal("GoldRoom", gold.name)
    assert_equal({}, gold.paths)
  end

  def test_room_paths()
    center = Map::Room.new("Center", "Test room in the center.")
    north = Map::Room.new("North", "Test room in the north.")
    south = Map::Room.new("South", "Test room in the south.")

    center.add_paths({'north' => north, 'south' => south})
    assert_equal(north, center.go('north'))
    assert_equal(south, center.go('south'))
  end


  def test_map()
    start = Map::Room.new("Start", "You can go west and down a hole.")
    west = Map::Room.new("Trees", "There are trees here, you can go east.")
    down = Map::Room.new("Dungeon", "It's dark down here, you can go up.")

    start.add_paths({'west' => west, 'down' => down})
    west.add_paths({'east' => start})
    down.add_paths({'up' => start})

    assert_equal(west, start.go('west'))
    assert_equal(start, start.go('west').go('east'))
    assert_equal(start, start.go('down').go('up'))
  end

    def test_gothon_game_map()
        assert_equal(Map::GENERIC_DEATH, Map::START.go('shoot!'))
        assert_equal(Map::GENERIC_DEATH, Map::START.go('dodge!'))

        room = Map::START.go('tell a joke')
        assert_equal(Map::LASER_WEAPON_ARMORY, room)

        room = room.go('0132')
        assert_equal(Map::THE_BRIDGE, room)

        # complete this test by making it play the game
        room = room.go('slowly place the bomb')
        assert_equal(Map::ESCAPE_POD, room)

        room = room.go('2')
        assert_equal(Map::THE_END_WINNER, room)


    end

  def test_game()
    # Integration test --> a series of steps 
    basement = Map::Room.new("BasementScene", "You can go to Dress.")
    dress = Map::Room.new("DressScene", "You can go to Necklace, Dress, or Lose.")
    necklace = Map::Room.new("NecklaceScene", "You can go to Zombie or Lose.")
    zombie = Map::Room.new("ZombieScene", "You can go to Merman or Lose.")
    merman = Map::Room.new("MermanScene", "You can go to Lose or Finish")
    lose = Map::Room.new("Lose", "You have lost the game. Nowhere to go.")
    finish = Map::Room.new("Finish", "You have won the game. Nowhere to go.")

    # from basement, can only go to dress
    basement.add_paths({'dress' => dress})
    # from dress, can go to necklace, dress, or lose
    dress.add_paths({'necklace' => necklace, 'dress' => dress, 'lose' => lose})
    # from necklace, can go to zombie, or lose
    necklace.add_paths({'zombie' => zombie, 'lose' => lose})
    # from zombie, can go to merman or lose
    zombie.add_paths({'merman' => merman, 'lose' => lose})
    # from merman, can go to lose or finish
    merman.add_paths({'lose' => lose, 'finish' => finish})
    ## lose and finish do not have paths to any other rooms

    # test that basement goes to dress, goes to dress, goes to lose
    assert_equal(lose, basement.go('dress').go('dress').go('lose'))
    # test that dress goes to necklace goes to lose
    assert_equal(lose, dress.go('necklace').go('lose'))
    # test that necklace goes to zombie, goes to lose
    assert_equal(lose, necklace.go('zombie').go('lose'))
    # test that zombie goes to merman, goes to lose
    assert_equal(lose, zombie.go('merman').go('lose'))
    # test that merman goes to finish
    assert_equal(finish, merman.go('finish'))
  end

  def test_session_loading()
        session = {}

        room = Map::load_room(session)
        assert_equal(room, nil)

        Map::save_room(session, Map::START)
        room = Map::load_room(session)
        assert_equal(room, Map::START)

        room = room.go('tell a joke')
        assert_equal(room, Map::LASER_WEAPON_ARMORY)

        Map::save_room(session, room)
        assert_equal(room, Map::LASER_WEAPON_ARMORY)
  end


    def temp_test_index
        session = {}

        get '/'
        follow_redirect!
        assert last_response.ok?
        assert last_response.body.include?('Central Corridor')
        puts last_response.body
        #room = Map::load_room(session)
    end

    def test_lwa 

        params = {:action => 'tell a joke'}
        post '/game', params 

        assert last_response.ok?
        #puts " Received response from POST LWA is: #{last_response.body}"

        get '/game'
        puts last_response.body
        assert last_response.body.include?('Laser Weapon Armory')

    end 


    def test_the_bridge 
        navigate_to(Map::THE_BRIDGE)

        assert last_response.ok?
        puts " Received response from POST THE_BRIDGE is: #{last_response.body}"
    end 

#  @rooms = [Map::START, Map::LASER_WEAPON_ARMORY, Map::THE_BRIDGE, Map::ESCAPE_POD, Map::THE_END_WINNER, Map::THE_END_LOSER]
#  @actions = {Map::START =>'tell a joke', Map::LASER_WEAPON_ARMORY=>'0132',  Map::THE_BRIDGE=>'slowly place the bomb',Map::ESCAPE_POD=>'2'}

    def navigate_to room_target 
         get '/'

         @rooms.each do |room| 
            puts "Room target is #{room_target} current room name is #{room}"
            if room == room_target 
                get '/game'
                break
            else
                action = @actions[room]
                puts "Action #{action} for room: #{room}"
                
                params = {:action => action}
                post '/game', params 
            end

         end

        #puts " Received response for Get Room: #{room_name} is: #{last_response.body}"
    end

end