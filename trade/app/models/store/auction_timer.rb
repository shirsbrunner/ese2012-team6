module Store
  class AuctionTimer

    # public for testing
    attr_accessor :check_interval, :last_refresh, :check_thread

    def initialize
      self.check_interval = 60 # 1 minute
      self.last_refresh = Time.now
    end

    # create new AuctionTimer with a timeout
    def self.timed(time)
      at = AuctionTimer.new
      at.check_interval = time
      at
    end

    # start governing trader's credits
    def start
      Thread.abort_on_exception = true
      self.last_refresh = Time.now

      self.check_thread = Thread.new {
        while true do
          if Time.now - self.last_refresh >= self.check_interval
            AuctionTimer.check_auctions
            self.last_refresh = Time.now
          end

          sleep 1
        end
      }
      self
    end

    # stop governing user's credits
    def stop
      self.check_thread.kill if self.check_thread
    end

    class << self
      # all credits get reduced in a special time interval
      def check_auctions
        Store::Item.allAuction.each{ |item|
          if item.end_time <= DateTime.now
            finish_auction item
          end
        }
      end

      def finish_auction item
        seller = item.owner
        buyer = item.current_winner

        seller.release_item(item)

        selling_price = item.currentSellingPrice
        buyers_bid = item.bidders[buyer]
        price = [selling_price, buyers_bid].min     # this fixes the situation where the loser bids 9, winner bids 10
                                                    # and the increment is 2. The winner would have to pay 11, but
                                                    # that's not fair, so we let him pay 10.

        seller.credits += price + Integer((price * Store::TradingAuthority.SELL_BONUS).ceil)
        # buyer.credits -= item.price       we have already taken them...

        item.deactivate
        buyer.attach_item(item)

        item.notify_change

        Analytics::ItemBuyActivity.with_buyer_item_price_success(buyer, item).log if log
      end
    end
  end
end