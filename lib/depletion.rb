require 'date'

class RecurringUse
  attr_reader :amount, :periodicity, :start_date, :end_date

  def initialize(amount, periodicity, start_date, end_date = nil)
    @amount = amount
    @periodicity = periodicity
    @start_date = start_date
    @end_date = end_date
  end
end

class UseQueue
  def initialize
    @head = nil
    @tail = nil
    @length = 0
  end

  def enqueue(use_node)
    if empty?
      @head = use_node
    else
      @tail.next = use_node
    end

    @tail = use_node
    @length += 1
    nil
  end

  def dequeue
    use_node = @head
    @head = use_node.next
    @length -= 1
    use_node
  end

  def peek_date
    @head.next_date
  end

  def empty?
    @length == 0
  end
end

class UseNode
  attr_reader :use
  attr_accessor :next_date, :next

  def initialize(use)
    @use = use
    @next_date = get_next_date(use)
    @next = nil
  end

  # calculate next use date if start date has passed
  def get_next_date(use)
    today = Date.today
    return use.start_date if use.start_date >= today
    return today if use.periodicity == 'daily'

    new_date = use.start_date
    new_date += 7 until new_date >= today
    new_date
  end
end

# simlate uses until current amount <= 0 to find the date of depletion
def predict_end_date(amount, *uses)
  current_amount = amount
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
    queue = next_queue(daily_queue, weekly_queue)
  end

  unless uses_array.empty? || queue.peek_date < uses_array.last.start_date
    return UseNode.new(uses_array.pop)
  end

  queue.dequeue
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
