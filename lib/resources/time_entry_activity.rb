class TimeEntryActivity < BaseResource
  def self.find_by_id(id)
    all.each do |activity|
      return activity if activity.id == id
    end
  end

  def self.safe_find_by_id(id)
    safe_all.each do |activity|
      return activity if activity.id == id
    end
  end

  def self.site=(url)
    super("#{url}/enumerations")
  end
end
