require 'date'
require_relative './use_queue.rb'

class RecurringUse
  attr_reader :amount, :periodicity, :start_date, :end_date

  def initialize(amount, periodicity, start_date, end_date = nil)
    @amount = amount
    @periodicity = periodicity
    @start_date = start_date
    @end_date = end_date
  end
end

# simlate uses until current amount <= 0 to find the date of depletion
def predict_end_date(current_amount, *uses)
  current_date = Date.today
  daily_queue = UseQueue.new
  weekly_queue = UseQueue.new
  uses_array = organize_uses(uses)

  loop do
    return nil if daily_queue.empty? && weekly_queue.empty? && uses_array.empty?

    use_node = next_use_node(daily_queue, weekly_queue, uses_array)
    current_amount -= use_node.use.amount
    return current_date if current_amount < 0
    return use_node.next_date if current_amount == 0

    current_date = use_node.next_date
    update_use(use_node, daily_queue, weekly_queue)
  end
end

# filter any expired uses and sort by start_date
def organize_uses(uses)
  array = uses.select { |use| use.end_date.nil? || use.end_date > Date.today }
  array.sort! { |x, y| y.start_date <=> x.start_date }
end

# find the use event that will occur next
def next_use_node(daily_queue, weekly_queue, uses_array)
  if daily_queue.empty? && weekly_queue.empty?
    return UseNode.new(uses_array.pop)
  else
    use_queue = next_queue(daily_queue, weekly_queue)
  end

  unless uses_array.empty? || use_queue.peek_date < uses_array.last.start_date
    return UseNode.new(uses_array.pop)
  end

  use_queue.dequeue
end

# find which queue has a sooner occuring use
def next_queue(daily, weekly)
  if daily.empty? || weekly.empty?
    use_queue = daily.empty? ? weekly : daily
  else
    use_queue = daily.peek_date <= weekly.peek_date ? daily : weekly
  end
  use_queue
end

# find the next time the use will occur and check if it passed the end date
def update_use(use_node, daily_queue, weekly_queue)
  if use_node.use.periodicity == 'daily'
    use_queue = daily_queue
    date_change = 1
  else
    use_queue = weekly_queue
    date_change = 7
  end

  use_node.next_date += date_change
  if use_node.use.end_date.nil? || use_node.use.end_date > use_node.next_date
    use_queue.enqueue(use_node)
  end

  nil
end
