class Demand < ActiveRecord::Base

  INTENSITIES = %w(LIGHT MODERATE HEAVY OCCUPY)

  attr_accessible :start_at, :end_at, :intensity, :consumer, :resource, :description, :short_description
  belongs_to :consumer, :class_name => 'User', :foreign_key => 'consumer_id'
  belongs_to :resource, :class_name => 'Resource', :foreign_key => 'resource_id'

  validates :intensity, :presence => true, :inclusion => {in: INTENSITIES}
  validates :start_at, :end_at, :consumer, :resource, :presence => true
  validate :validate_date_range_should_be_in_resource_date_range
  include DateRangeValidation

  before_create :create_event
  before_update :update_event
  before_destroy :delete_event

  def consumer_name
  	consumer.name
  end

  def self.find_from_event_id(resource, e_id)
    find_by_event_id "#{resource.cal_id}/private/full/#{e_id}"  
  end

  private

  def validate_date_range_should_be_in_resource_date_range
    unless resource && start_at && end_at
      errors[:resource_date_range] << "Nil columns!" 
      return
    end

    if start_at < resource.start_at || end_at > resource.end_at
      errors[:resource_date_range] << "Validate date range should be in resource date range."
    end
  end

  def create_event
    service = get_gcal_service
    event = GCal4Ruby::Event.new(service)
    modify_event event, service
    self.event_id = event.id
  end

  def update_event
    service = get_gcal_service
    event = GCal4Ruby::Event.find(service, {:id => event_id})
    modify_event event, service
  end

  def delete_event
    service = get_gcal_service
    event = GCal4Ruby::Event.find(service, {:id => event_id})
    event.delete
  end

  def get_gcal_service
    service = GCal4Ruby::Service.new
    service.authenticate
    service
  end

  def modify_event event, service
    cal = GCal4Ruby::Calendar.find(service, {:id => resource.cal_id})
    event.calendar = cal
    event.all_day = true
    event.start_time = start_at.to_s
    event.end_time = end_at.to_s
    event.title = "[#{intensity}] #{short_description}"
    event.save
  end

end
