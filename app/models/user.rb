class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :journals, dependent: :destroy
  has_many :mistakes, dependent: :destroy
  has_one :notification_setting, dependent: :destroy
  has_many :journal_corrections, dependent: :destroy

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable

  def total_journal_count
    journals.distinct.count
  end

  def this_month_journal_count
    journals.where(posted_date: Date.current.all_month).distinct.count
  end

  def total_learning_count
    mistakes.joins(:journal)
            .where("learning_points ->> 'pattern' IS NOT NULL")
            .where.not("learning_points ->> 'pattern' = ''")
            .distinct
            .count
  end

  def this_month_learning_count
    mistakes.joins(:journal)
            .where(journals: { posted_date: Date.current.all_month })
            .where("learning_points ->> 'pattern' IS NOT NULL")
            .where.not("learning_points ->> 'pattern' = ''")
            .distinct
            .count
  end

  def streak_dates
    posted_dates = journals.distinct.pluck(:posted_date)

    count = 0
    date = posted_dates.include?(Date.current) ? Date.current : Date.yesterday

    while posted_dates.include?(date)
      count += 1
      date -= 1.day
    end
    count
  end
end
