require 'rspec'
require 'depletion'

describe 'UseNode' do
  subject(:node) do
    use = RecurringUse.new(50, 'daily', Date.today + 1)
    UseNode.new(use)
  end
  subject(:past_node_daily) do
    use = RecurringUse.new(50, 'daily', Date.today - 5)
    UseNode.new(use)
  end
  subject(:past_node_weekly) do
    use = RecurringUse.new(50, 'weekly', Date.today - 13)
    UseNode.new(use)
  end

  describe 'UseNode#use' do
    it 'returns a RecurringUse instance' do
      expect(node.use.class).to eq(RecurringUse)
    end
  end

  describe 'UseNode#next_date' do
    it 'returns the correct date' do
      expect(node.next_date).to eq(Date.today + 1)
    end

    it 'sets next date if start date has passed and periodicity is daily' do
      expect(past_node_daily.next_date).to eq(Date.today)
    end

    it 'sets next date if start date has passed and periodicity is weekly' do
      expect(past_node_weekly.next_date).to eq(Date.today + 1)
    end

    it 'allows the next date to be changed' do
      past_node_daily.next_date += 5
      expect(past_node_daily.next_date).to eq(Date.today + 5)
    end
  end
end

describe 'UseQueue' do
  subject(:queue) { UseQueue.new }
  subject(:empty_queue) { UseQueue.new }
  let(:node1) do
    use1 = RecurringUse.new(50, 'daily', Date.today)
    UseNode.new(use1)
  end
  let(:node2) do
    use2 = RecurringUse.new(10, 'weekly', Date.today)
    UseNode.new(use2)
  end

  before(:each) do
    queue.enqueue(node1)
  end

  describe 'UseQueue#enqueue' do
    it 'adds a node to an empty queue' do
      expect(queue.empty?).to eq(false)
    end

    it 'adds a node to the end of a queue' do
      queue.enqueue(node2)
      expect(queue.dequeue).not_to eq(node2)
    end

    it 'sets the tail node\'s next node' do
      queue.enqueue(node2)
      expect(node1.next).to eq(node2)
    end

    it 'increments the queue length' do
      expect(queue.empty?).to eq(false)
    end
  end

  describe 'UseQueue#dequeue' do
    it 'removes a node from a queue' do
      queue.dequeue
      expect(queue.empty?).to eq(true)
    end

    it 'returns the first node in a queue' do
      queue.enqueue(node2)
      expect(queue.dequeue).to eq(node1)
    end

    it 'decrements the queue length' do
      queue.dequeue
      expect(queue.empty?).to eq(true)
    end
  end

  describe 'UseQueue#peek_date' do
    it 'returns the date of the first use in a queue' do
      queue.enqueue(node2)
      expect(queue.peek_date).to eq(node1.next_date)
    end
  end

  describe 'UseQueue#empty?' do
    it 'returns true when queue is empty' do
      expect(empty_queue.empty?).to eq(true)
    end

    it 'returns false when queue is not empty' do
      empty_queue.enqueue(node1)
      expect(empty_queue.empty?).to eq(false)
    end
  end
end

describe '#organize_uses' do
  let(:use1) { RecurringUse.new(10, 'daily', Date.today) }
  let(:use2) { RecurringUse.new(10, 'weekly', Date.today + 1) }
  let(:use3) { RecurringUse.new(10, 'daily', Date.today + 2) }
  let(:use_past) { RecurringUse.new(10, 'daily', Date.today, Date.today - 1) }

  it 'sorts uses by start date in descending order' do
    uses = organize_uses([use1, use2, use3])
    expect(uses.last).to eq(use1)
  end

  it 'filters uses that have ended before the current date' do
    uses = organize_uses([use1, use2, use3, use_past])
    expect(uses.length).to eq(3)
  end
end

describe '#next_use_node' do
  let(:daily_queue) { UseQueue.new }
  let(:weekly_queue) { UseQueue.new }
  let(:use1) { RecurringUse.new(10, 'daily', Date.today + 1) }
  let(:use2) { RecurringUse.new(10, 'weekly', Date.today + 2) }
  let(:use3) { RecurringUse.new(10, 'daily', Date.today + 3) }

  it 'returns a UserNode instance' do
    use_node = next_use_node(daily_queue, weekly_queue, [use1])
    expect(use_node.class).to eq(UseNode)
  end

  it 'returns a UserNode using the uses array when the queues are empty' do
    use_node = next_use_node(daily_queue, weekly_queue, [use1])
    expect(use_node.use).to eq(use1)
  end

  it 'pops from the uses array when its last element is the next use' do
    daily_queue.enqueue(UseNode.new(use3))
    weekly_queue.enqueue(UseNode.new(use2))
    use_node = next_use_node(daily_queue, weekly_queue, [use1])
    expect(use_node.use).to eq(use1)
  end

  it 'dequeues the daily queue when its head is the next use' do
    daily_queue.enqueue(UseNode.new(use1))
    weekly_queue.enqueue(UseNode.new(use2))
    use_node = next_use_node(daily_queue, weekly_queue, [use3])
    expect(use_node.use).to eq(use1)
  end

  it 'dequeues the weekly queue when its head is the next use' do
    use = RecurringUse.new(10, 'weekly', Date.today)
    daily_queue.enqueue(UseNode.new(use1))
    weekly_queue.enqueue(UseNode.new(use))
    use_node = next_use_node(daily_queue, weekly_queue, [use3])
    expect(use_node.use).to eq(use)
  end
end

describe '#update_use' do
  subject(:node_daily) do
    use_daily = RecurringUse.new(50, 'daily', Date.today, Date.today + 5)
    UseNode.new(use_daily)
  end
  subject(:node_weekly) do
    use_weekly = RecurringUse.new(10, 'weekly', Date.today, Date.today + 5)
    UseNode.new(use_weekly)
  end
  let(:queue) { UseQueue.new }

  it 'updates the date for daily uses' do
    update_use(node_daily, queue)
    expect(node_daily.next_date).to eq(Date.today + 1)
  end

  it 'updates the date for weekly uses' do
    update_use(node_weekly, queue)
    expect(node_weekly.next_date).to eq(Date.today + 7)
  end

  it 'enqueues uses not past their end date' do
    update_use(node_daily, queue)
    expect(queue.dequeue).to eq(node_daily)
  end

  it 'does not enqueue uses past their end date' do
    update_use(node_weekly, queue)
    expect(queue.empty?).to eq(true)
  end
end

describe '#predict_end_date' do
  let(:use1) { RecurringUse.new(10, 'daily', Date.today) }
  let(:use2) { RecurringUse.new(10, 'daily', Date.today) }
  let(:use3) { RecurringUse.new(20, 'weekly', Date.today) }
  let(:use4) { RecurringUse.new(40, 'weekly', Date.today) }
  let(:use_start1) { RecurringUse.new(10, 'daily', Date.today + 10) }
  let(:use_start2) { RecurringUse.new(20, 'weekly', Date.today + 5) }
  let(:use_end1) { RecurringUse.new(10, 'daily', Date.today, Date.today + 5) }
  let(:use_end2) { RecurringUse.new(20, 'weekly', Date.today, Date.today + 10) }
  let(:use_past) { RecurringUse.new(10, 'daily', Date.today, Date.today - 1) }

  it 'returns correct date when given one use' do
    end_date = predict_end_date(50, use1)
    expect(end_date).to eq(Date.today + 4)
  end

  it 'returns correct date when given multiple uses' do
    end_date = predict_end_date(500, use1, use2, use3, use4)
    expect(end_date).to eq(Date.today + 15)
  end

  it 'returns correct date when current amount becomes negative' do
    end_date = predict_end_date(501, use1, use2, use3, use4)
    expect(end_date).to eq(Date.today + 15)
  end

  it 'returns correct date when given uses with varying start dates' do
    end_date = predict_end_date(410, use1, use4, use_start1, use_start2)
    expect(end_date).to eq(Date.today + 17)
  end

  it 'returns correct date when given uses with end dates' do
    end_date = predict_end_date(400, use1, use4, use_end1, use_end2)
    expect(end_date).to eq(Date.today + 18)
  end

  it 'returns correct date when given many complex uses' do
    end_date = predict_end_date(
      1000, use1, use2, use3, use4, use_start1, use_start2, use_end1, use_end2
    )
    expect(end_date).to eq(Date.today + 23)
  end

  it 'filters uses that have already ended' do
    end_date = predict_end_date(50, use1, use_past)
    expect(end_date).to eq(Date.today + 4)
  end

  it 'returns nil if uses do not consume entire amount' do
    expect(predict_end_date(100, use_end1, use_end2)).to eq(nil)
  end
end
