class SentMessage < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :employee
  belongs_to :message, polymorphic: true

  validates :employee, presence: true, uniqueness: {
    scope: [:message_id, :message_type],
  }
  validates :message_body, presence: true
  validates :message, presence: true
  validates :sent_at, presence: true
  validates :sent_on, presence: true

  delegate :slack_username, to: :employee

  def self.by_year(year)
    where("extract(year from created_at) = ?", year)
  end

  def self.filter(params)
    if params[:slack_username].present? ||
        params[:message_body].present? ||
        params[:sent_on].present?

      @employees = Employee.where(
        "slack_username like ?",
        "%#{params[:slack_username].downcase}%",
      )

      results = none

      if @employees
        @employees.each do |e|
          new_results = where(employee_id: e.id)
          results = results.union(new_results)
        end
      end

      results = results.where(
        "lower(message_body) like ?",
        "%#{params[:message_body].downcase}%",
      )

      if !params[:sent_on].blank?
        results = results.where(sent_on: params[:sent_on])
      end

      results
    else
      all
    end
  end
end
