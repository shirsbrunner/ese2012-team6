require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/store/user'
require_relative '../app/models/store/trader'
require_relative '../app/models/store/organization'
require_relative '../app/models/store/item'

class TraderTest < Test::Unit::TestCase
  include Store

  def setup
    Trader.clear_all
  end

  def teardown
    Trader.clear_all
  end

  def test_creation_default
    user = Trader.named("Hans")
    assert_equal(0, user.credits)
    assert_equal("", user.description)
    assert_equal(0, user.items.size)
    assert_equal("/images/no_image.gif", user.image_path)
  end

  def test_creation_with_credits
    user = Trader.named("Hans", :credits => 100)
    assert_equal(100, user.credits)
  end

  def test_creation_with_description
    user = Trader.named("Hans", :description => "New description")
    assert_equal("New description", user.description)
  end

  def test_user_proposes_item
    user = Trader.named("User")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil)

    assert_equal(false, item.active, "Newly created items must be inactive!")
    assert_equal(user, item.owner , "Item with no assigned owner created!")
  end

  def test_fetch_all
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal([user, org], Trader.all)
  end

  def test_fetch_by_name
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal(user, Trader.by_name("User1"))
    assert_equal(org, Trader.by_name("Org1"))
  end

  def test_exists_by_name
    (user = User.named("User1")).save
    (org = Organization.named("Org1")).save

    assert_equal(true, Trader.exists?("User1"))
    assert_equal(true, Trader.exists?("Org1"))
    assert_equal(false, Trader.exists?("User2"))
    assert_equal(false, Trader.exists?("Org2"))
  end

  def test_user_active_items_list
    user = Trader.named("User")

    user.propose_item("TestItem1", 1, "fixed", nil, nil)
    item2 = user.propose_item("TestItem2", 2, "fixed", nil, nil)
    user.propose_item("TestItem3", 3, "fixed", nil, nil)
    item4 = user.propose_item("TestItem4", 4, "fixed", nil, nil)

    item2.activate
    item4.activate

    active_items = [item2, item4]
    active_items_user = user.get_active_items

    # '==' operator of Array class tests for equal length and matching elements, does not compare references!
    assert_equal(active_items, active_items_user, "Item lists do not match!")
  end

  def test_user_buy_success
    buyer = Trader.named("Buyer", :credits => 100)
    seller = Trader.named("Seller", :credits => 100)

    item = seller.propose_item("piece of crap", 100, "fixed", nil, nil)
    item.activate

    buyer.acknowledge_item_properties!

    transaction_result, transaction_message = buyer.buy_item(item)
    assert(transaction_result, "Transaction failed when it should have succeeded\nReason: #{transaction_message}")

    assert_equal(0, buyer.credits, "Buyer has too many credits left")
    assert_equal(205, seller.credits, "Seller has too few credits") #notice sell bonus!

    assert(!seller.items.include?(item), "Seller still owns the sold item")
    assert(buyer.items.include?(item), "Buyer doesn't have the item")
    assert_equal(buyer, item.owner, "Item has the wrong owner")

    assert(!item.active?, "Item is still active")
  end

  def test_user_buy_inactive_item
    buyer = Trader.named("Buyer", :credits => 100)
    seller = Trader.named("Seller", :credits => 100)

    item = seller.propose_item("piece of crap", 100, "fixed", nil, nil)
    buyer.acknowledge_item_properties!
    assert(!item.active?)

    transaction_result, transaction_message = buyer.buy_item(item)

    assert(transaction_result == false,"Transaction should have failed but it did not")

    assert_equal(100, buyer.credits, "Buyer's credits changed when they should not have")
    assert_equal(100, seller.credits, "Seller's credits changed when they should not have")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert_equal(seller, item.owner, "Item has the wrong owner")
  end

  def test_user_buy_too_expensive
    buyer = Trader.named("Buyer", :credits => 100)
    seller = Trader.named("Seller", :credits => 100)

    item = seller.propose_item("big piece of crap", 9001, "fixed", nil, nil) #item price is over 9000!
    item.activate
    buyer.acknowledge_item_properties!
    assert(item.active?)

    transaction_result, transaction_message = buyer.buy_item(item)

    assert(transaction_result == false,"Transaction should have failed but it did not")

    assert_equal(100, buyer.credits, "Buyer has wrong amount of credits")
    assert_equal(100, seller.credits, "Seller has wrong amount of credits")

    assert(seller.items.include?(item), "Seller does not own the item it wants to sell")
    assert(!buyer.items.include?(item), "Buyer bought the item when it should not have been able to do so")
    assert_equal(seller, item.owner, "Item has the wrong owner")
  end

  def test_send_money_to
    user1 = Trader.named("User1", :credits => 100)
    user2 = Trader.named("User2", :credits => 100)

    user1.send_money_to(user2, 50)

    assert_equal(50, user1.credits)
    assert_equal(150, user2.credits)
  end

  def test_user_can_buy_own_item
    user = Trader.named("Hans")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil, "", false)
    assert_equal(false, user.can_buy?(item), "Should not be able to buy own items")
  end

  def test_user_can_buy_other_item
    user = Trader.named("Hans")
    other = Trader.named("Herbert")

    item = other.propose_item("TestItem", 100, "fixed", nil, nil, "", false)
    assert_equal(false, user.can_buy?(item))
    item.activate
    assert_equal(true, user.can_buy?(item))
  end

  def test_can_edit_own_item
    user = Trader.named("Hans")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil, "", false)
    assert_equal(true, user.can_edit?(item))
    item.activate
    assert_equal(false, user.can_edit?(item))
  end

  def test_can_edit_other_item
    user = Trader.named("Hans")
    other = Trader.named("Herbert")
    item = other.propose_item("TestItem", 100, "fixed", nil, nil, "", false)

    assert_equal(false, user.can_edit?(item))
    assert_equal(true, other.can_edit?(item))

    item.activate
    assert_equal(false, user.can_edit?(item))
    assert_equal(false, user.can_edit?(item))
  end

  def test_can_delete_own_item
    user = Trader.named("Hans")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil, "", false)
    assert_equal(true, user.can_delete?(item))
    item.activate
    assert_equal(false, user.can_edit?(item))
  end

  def test_delete_item
    user = Trader.named("Hans")
    item = user.propose_item("TestItem", 100, "fixed", nil, nil, "", false)

    assert_equal(true, user.can_delete?(item))

    user.delete_item(item.id, false)

    assert_equal(false, user.items.include?(item))
  end
end