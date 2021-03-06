require_relative 'spec_helper'

describe "HotelBooker Class" do
  describe "HotelBooker initation" do
    let(:booker) {Hotel::HotelBooker.new}

    it "Returns an instance of HotelBooker" do
      expect(booker).must_be_kind_of Hotel::HotelBooker
    end

    it "Establishes the base data structures when instantiated" do
      [:rooms, :reservations].each do |prop|
        expect(booker).must_respond_to prop
      end
      expect(booker.rooms).must_be_kind_of Array
      expect(booker.reservations).must_be_kind_of Array
    end

    it "Loads 20 Rooms" do
      expect(booker.rooms.length).must_equal 20
      20.times do |i|
        expect(booker.rooms[i]).must_be_kind_of Hotel::Room
      end
    end
  end

  describe "Make a reservation method" do
    before do
      @booker = Hotel::HotelBooker.new
    end

    it "adds a Reservation to the list of reservations" do
      @booker.make_reservation(1, '2018-09-05', '2018-09-07')
      expect(@booker.reservations.length).must_equal 1
      expect(@booker.reservations[0]).must_be_kind_of Hotel::Reservation
    end

    it "adds a Reservation which contains an instance of Room" do
      @booker.make_reservation(1, '2018-09-05', '2018-09-07')
      expect(@booker.reservations[0].room).must_be_kind_of Hotel::Room
    end

    it "raises a StandardError if there are no available rooms for the date range" do
      20.times do |i|
        @booker.make_reservation(i+1, '2018-09-05', '2018-09-07')
      end

      expect{ @booker.make_reservation(21, '2018-09-05', '2018-09-07') }.must_raise StandardError
    end
  end

  describe "Find a reservation by date method" do
    before do
      @booker = Hotel::HotelBooker.new
      @booker.make_reservation(1, '2018-09-05', '2018-09-08')
      @booker.make_reservation(2, '2018-09-06', '2018-09-08')
      @booker.make_reservation(3, '2018-09-07', '2018-09-09')
    end

    it "returns an array of reservations if there are reservations" do
      expect(@booker.find_reservations('2018-09-05')).must_be_kind_of Array
      expect(@booker.find_reservations('2018-09-06')[0]).must_be_kind_of Hotel::Reservation
      expect(@booker.find_reservations('2018-09-07').length).must_equal 3
    end

    it "returns an empty array if there are no reservations for that date" do
      expect(@booker.find_reservations('2019-10-13')).must_equal []
    end
  end

  describe "unreserved_rooms method" do
    before do
      @date1 = Date.parse('2018-09-05')
      @date2 = Date.parse('2018-09-09')
      @date3 = Date.parse('2018-09-10')
      @date4 = Date.parse('2018-09-11')

      @booker = Hotel::HotelBooker.new
      @booker.make_reservation(1, '2018-09-05', '2018-09-08')
      @booker.make_reservation(2, '2018-09-06', '2018-09-08')
      @booker.make_reservation(3, '2018-09-07', '2018-09-09')
    end

    it "returns an array of unreserved rooms for date range given unreserved rooms exist" do
      expect(@booker.unreserved_rooms(@date1, @date2)).must_be_kind_of Array
      expect(@booker.unreserved_rooms(@date1, @date2).length).must_equal 17
      expect(@booker.unreserved_rooms(@date1, @date2)[0]).must_be_kind_of Hotel::Room
      expect(@booker.unreserved_rooms(@date1, @date2)[0].id).must_equal 4
    end

    it "returns array of 20 rooms given if there no reservations for the date" do
      expect(@booker.unreserved_rooms(@date3, @date4)).must_be_kind_of Array
      expect(@booker.unreserved_rooms(@date3, @date4).length).must_equal 20
    end
  end

  describe "Make block of rooms" do
    before do
      @booker = Hotel::HotelBooker.new
    end

    it "raises StandardError if user tries to create a block with more than 5 rooms" do
      expect{ @booker.make_block(6, 150, '2018-09-05', '2018-09-10') }.must_raise StandardError
    end

    it "raises StandardError if there are not enough available rooms for a block" do
      20.times do |i|
        @booker.make_reservation(i+1, '2018-09-05', '2018-09-10')
      end

      expect{ @booker.make_block(1, 150, '2018-09-05', '2018-09-10') }.must_raise StandardError
    end

    it "creates an array of available block reservations" do
      expect(@booker.make_block(5, 150, '2018-09-05', '2018-09-10')).must_be_kind_of Array
    end

    it "creates an array the size of Reservations described by rooms" do
      expect(@booker.make_block(5, 150, '2018-09-05', '2018-09-10').length).must_equal 5
    end

    it "creates an array carrying instances of Reservation" do
      expect(@booker.make_block(5, 150, '2018-09-05', '2018-09-10')[4]).must_be_kind_of Hotel::Reservation
    end

    it "carries instances of Reservation with adjusted cost" do
      expect(@booker.make_block(1, 150, '2018-09-05', '2018-09-10')[0].cost).must_equal 750
    end

    it "assigns rooms starting from available rooms" do
      10.times do |i|
        @booker.make_reservation(i+1, '2018-09-05', '2018-09-10')
      end
      expect(@booker.make_block(5, 150, '2018-09-05', '2018-09-10')[0].room.id).must_equal 11
    end

    it "reservation dates match the date range of the block" do
      @booker.make_block(1, 150, '2018-09-05', '2018-09-10')
      dates = @booker.unreserved_block[0].date_range
      same_range = @booker.range(Date.parse('2018-09-05'), Date.parse('2018-09-10'))
      expect(dates.check_in).must_equal same_range.check_in
      expect(dates.check_out).must_equal same_range.check_out
    end
  end

  describe "make_block_reservation method" do
    before do
      @booker = Hotel::HotelBooker.new
    end

    it "raises an error if there are no avaiable block reservations" do
      expect{ @booker.make_block_reservation(1) }.must_raise StandardError
    end

    it "moves a reservation from @unreserved_block to @reserve_block" do
      @booker.make_block(1, 150, '2018-09-05', '2018-09-10')
      @booker.make_block_reservation(1)

      expect(@booker.unreserved_block.length).must_equal 0
      expect(@booker.reserved_block.length).must_equal 1
      expect(@booker.reserved_block[0]).must_be_kind_of Hotel::Reservation
    end
  end

  describe "unreserved_block_rooms method" do
    before do
      @booker = Hotel::HotelBooker.new
      @booker.make_block(5, 150, '2018-09-05', '2018-09-10')
    end

    it "returns an array of available rooms marked for block reservations" do
      expect(@booker.unreserved_block_rooms).must_be_kind_of Array
      expect(@booker.unreserved_block_rooms[0]).must_be_kind_of Hotel::Room
      expect(@booker.unreserved_block_rooms.length).must_equal 5
    end
  end
end
