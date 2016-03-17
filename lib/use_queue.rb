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
    return nil if empty?
    use_node = @head
    @head = use_node.next
    @length -= 1
    use_node
  end

  def peek_date
    return nil if empty?
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

  private

  # calculate next use date if start date has passed
  def get_next_date(use)
    today = Date.today
    return use.start_date if use.start_date >= today
    return today if use.periodicity == 'daily'

    next_week_date(use.start_date)
  end

  def next_week_date(date)
    date += 7 until date >= Date.today
    date
  end
end
